/**
 * 串口工具模块
 * 使用 Web Serial API 实现串口通信
 */

export interface SerialPortInfo {
  port: SerialPort;
  productName?: string;
  manufacturer?: string;
}

/**
 * 检查浏览器是否支持 Web Serial API
 */
export function isSerialSupported(): boolean {
  return 'serial' in navigator;
}

/**
 * 请求用户选择串口设备
 */
export async function requestSerialPort(): Promise<SerialPort | null> {
  try {
    const port = await navigator.serial.requestPort();
    return port;
  } catch (error) {
    if (error instanceof DOMException && error.name === 'NotFoundError') {
      console.log('用户取消了端口选择');
      return null;
    }
    throw error;
  }
}

/**
 * 获取已授权的串口列表
 */
export async function getAvailablePorts(): Promise<SerialPort[]> {
  return await navigator.serial.getPorts();
}

/**
 * 打开串口连接
 */
export async function openSerialPort(
  port: SerialPort,
  baudRate: number = 115200
): Promise<void> {
  await port.open({ baudRate });
}

/**
 * 关闭串口连接
 */
export async function closeSerialPort(port: SerialPort): Promise<void> {
  if (port.readable) {
    try {
      await port.close();
    } catch (error) {
      console.error('关闭串口时出错:', error);
    }
  }
}

/**
 * 读取串口数据（指定字节数）
 */
export async function readBytes(
  reader: ReadableStreamDefaultReader<Uint8Array>,
  byteCount: number,
  timeoutMs: number = 10000
): Promise<Uint8Array> {
  const buffer = new Uint8Array(byteCount);
  let bytesRead = 0;

  return await new Promise<Uint8Array>((resolve, reject) => {
    const timeoutId = setTimeout(() => {
      reject(new Error('读取超时'));
    }, timeoutMs);

    const readLoop = async () => {
      try {
        while (bytesRead < byteCount) {
          const { value, done } = await reader.read();
          if (done) {
            throw new Error(`数据流已关闭，只读取到 ${bytesRead} 字节`);
          }

          const remainingBytes = byteCount - bytesRead;
          const bytesToCopy = Math.min(value.length, remainingBytes);
          buffer.set(value.slice(0, bytesToCopy), bytesRead);
          bytesRead += bytesToCopy;
        }
        resolve(buffer);
      } catch (error) {
        reject(error);
      } finally {
        clearTimeout(timeoutId);
      }
    };

    void readLoop();
  });
}

/**
 * 写入串口数据
 */
export async function writeBytes(
  writer: WritableStreamDefaultWriter<Uint8Array>,
  data: Uint8Array
): Promise<void> {
  await writer.write(data);
}

/**
 * 清空串口输入缓冲区（通过读取所有可用数据）
 * 注意：此函数不再使用，因为会导致 reader 锁定问题
 */
export async function flushInput(_port: SerialPort): Promise<void> {
  // 不做任何操作，避免 reader 锁定
  // 串口数据会在读取时自然清空
  return;
}
