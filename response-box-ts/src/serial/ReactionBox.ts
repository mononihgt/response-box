import { openSerialPort, closeSerialPort, writeBytes } from './SerialUtils';

export interface ReactionTimeData {
  key: number;
  t1: number;
  t2: number;
  pressDuration: number;
  softwareRT: number;
  systemDelay: number;
  ide: number;
}

interface PendingFrameWaiter {
  resolve: (frame: Uint8Array) => void;
  reject: (error: unknown) => void;
  timeoutId: ReturnType<typeof setTimeout>;
  abortHandler?: () => void;
  signal?: AbortSignal;
}

export class ReactionBox {
  private port: SerialPort | null = null;
  private baudRate: number = 115200;
  private reader: ReadableStreamDefaultReader<Uint8Array> | null = null;
  private readLoopPromise: Promise<void> | null = null;
  private frameBuffer: number[] = [];
  private pendingFrameWaiter: PendingFrameWaiter | null = null;

  constructor(baudRate: number = 115200) {
    this.baudRate = baudRate;
  }

  async connect(port: SerialPort): Promise<void> {
    if (port.readable && port.writable) {
      console.log('Serial port is already open; reusing it.');
      this.port = port;
      this.ensureReadLoop();
      return;
    }

    this.port = port;
    await openSerialPort(port, this.baudRate);
    this.ensureReadLoop();
  }

  async disconnect(): Promise<void> {
    if (this.port) {
      await this.stopReadLoop();
      await closeSerialPort(this.port);
      this.port = null;
    }
  }

  isConnected(): boolean {
    return this.port !== null && this.port.readable !== null;
  }

  async getReactionTime(timeoutMs: number = 10000, signal?: AbortSignal): Promise<ReactionTimeData> {
    if (!this.port || !this.port.readable || !this.port.writable) {
      throw new Error('Serial port is not connected.');
    }

    this.ensureReadLoop();
    this.clearReadState();

    const frameWaiter = this.waitForNextFrame(timeoutMs, signal);

    try {
      await this.writeCommand(new Uint8Array([0xFC, 0x00]));
      await new Promise(resolve => setTimeout(resolve, 10));

      const triggerTime = performance.now();
      await this.writeCommand(new Uint8Array([0xFB, 0x00]));

      const frame = await frameWaiter;
      const receiveTime = performance.now();
      const softwareRT = receiveTime - triggerTime;

      if (frame[0] !== 0xFB) {
        throw new Error(`Invalid frame header: 0x${frame[0].toString(16).padStart(2, '0')}`);
      }

      if (frame[1] < 0x01 || frame[1] > 0x05) {
        throw new Error(`Invalid key code: 0x${frame[1].toString(16).padStart(2, '0')}`);
      }

      const key = frame[1];
      const t1 = (frame[2] << 8) | frame[3];
      const t2 = (frame[4] << 8) | frame[5];
      const ide = (frame[6] << 8) | frame[7];

      return {
        key,
        t1,
        t2,
        pressDuration: t2 - t1,
        softwareRT,
        systemDelay: softwareRT - t2,
        ide
      };
    } catch (error) {
      this.cancelPendingFrame(error);
      throw error;
    }
  }

  async stopTiming(): Promise<void> {
    if (!this.port || !this.port.writable) {
      return;
    }

    this.cancelPendingFrame(new Error('Read cancelled.'));

    try {
      await this.writeCommand(new Uint8Array([0xFC, 0x00]));
      this.clearReadState();
    } catch (error) {
      console.error('Failed to stop timing:', error);
    }
  }

  async testConnection(): Promise<boolean> {
    if (!this.port || !this.port.writable) {
      return false;
    }

    try {
      await this.writeCommand(new Uint8Array([0xFC, 0x00]));
      return true;
    } catch (error) {
      console.error('Connection test failed:', error);
      return false;
    }
  }

  private ensureReadLoop(): void {
    if (this.readLoopPromise) {
      return;
    }

    if (!this.port || !this.port.readable) {
      throw new Error('Serial port is not connected.');
    }

    this.reader = this.port.readable.getReader();
    this.readLoopPromise = this.runReadLoop();
  }

  private async runReadLoop(): Promise<void> {
    const reader = this.reader;
    if (!reader) {
      return;
    }

    try {
      while (true) {
        const { value, done } = await reader.read();
        if (done) {
          break;
        }

        if (value.length > 0) {
          this.appendSerialBytes(value);
        }
      }
    } catch (error) {
      this.cancelPendingFrame(error);
    } finally {
      this.cancelPendingFrame(new Error('Serial data stream closed.'));
      this.frameBuffer = [];
      try {
        reader.releaseLock();
      } catch {
        // Ignore cleanup errors after the stream has already closed.
      }
      if (this.reader === reader) {
        this.reader = null;
      }
      this.readLoopPromise = null;
    }
  }

  private async stopReadLoop(): Promise<void> {
    this.cancelPendingFrame(new Error('Serial port disconnected.'));

    const reader = this.reader;
    if (reader) {
      try {
        await reader.cancel();
      } catch {
        // Ignore cancellation errors while disconnecting.
      }
    }

    if (this.readLoopPromise) {
      await this.readLoopPromise.catch(() => undefined);
    }
  }

  private appendSerialBytes(bytes: Uint8Array): void {
    this.frameBuffer.push(...bytes);
    this.resolveAvailableFrames();
  }

  private resolveAvailableFrames(): void {
    while (this.frameBuffer.length >= 1) {
      const headerIndex = this.frameBuffer.indexOf(0xFB);
      if (headerIndex < 0) {
        this.frameBuffer = [];
        return;
      }

      if (headerIndex > 0) {
        this.frameBuffer.splice(0, headerIndex);
      }

      if (this.frameBuffer.length < 8) {
        return;
      }

      const frame = new Uint8Array(this.frameBuffer.slice(0, 8));
      this.frameBuffer.splice(0, 8);

      if (this.pendingFrameWaiter) {
        const waiter = this.pendingFrameWaiter;
        this.pendingFrameWaiter = null;
        this.cleanupFrameWaiter(waiter);
        waiter.resolve(frame);
      }
      // Frames with no active waiter are stale data from a previous timing run.
    }
  }

  private waitForNextFrame(timeoutMs: number, signal?: AbortSignal): Promise<Uint8Array> {
    if (this.pendingFrameWaiter) {
      throw new Error('A serial read is already pending.');
    }

    return new Promise<Uint8Array>((resolve, reject) => {
      const timeoutId = setTimeout(() => {
        this.cancelPendingFrame(new Error('Read timed out.'));
      }, timeoutMs);

      const waiter: PendingFrameWaiter = {
        resolve,
        reject,
        timeoutId,
        signal
      };

      if (signal) {
        waiter.abortHandler = () => {
          this.cancelPendingFrame(new Error('Read cancelled.'));
        };
        signal.addEventListener('abort', waiter.abortHandler, { once: true });
      }

      this.pendingFrameWaiter = waiter;
    });
  }

  private cancelPendingFrame(error: unknown): void {
    if (!this.pendingFrameWaiter) {
      return;
    }

    const waiter = this.pendingFrameWaiter;
    this.pendingFrameWaiter = null;
    this.cleanupFrameWaiter(waiter);
    waiter.reject(error);
  }

  private cleanupFrameWaiter(waiter: PendingFrameWaiter): void {
    clearTimeout(waiter.timeoutId);
    if (waiter.signal && waiter.abortHandler) {
      waiter.signal.removeEventListener('abort', waiter.abortHandler);
    }
  }

  private clearReadState(): void {
    this.frameBuffer = [];
  }

  private async writeCommand(data: Uint8Array): Promise<void> {
    if (!this.port || !this.port.writable) {
      throw new Error('Serial port is not connected.');
    }

    const writer = this.port.writable.getWriter();
    try {
      await writeBytes(writer, data);
    } finally {
      writer.releaseLock();
    }
  }
}
