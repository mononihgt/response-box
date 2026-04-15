/**
 * 实验管理器
 * 提供实验流程控制和数据记录功能
 */

import { ReactionBox, ReactionTimeData } from '../serial/ReactionBox';

type WritableFileStreamLike = {
  write(data: string): Promise<void>;
  close(): Promise<void>;
};

type FileHandleLike = {
  createWritable(): Promise<WritableFileStreamLike>;
};

type DirectoryHandleLike = {
  getFileHandle(name: string, options?: { create?: boolean }): Promise<FileHandleLike>;
};

type DirectoryPickerWindow = Window & {
  showDirectoryPicker?: (options?: { mode?: 'read' | 'readwrite' }) => Promise<DirectoryHandleLike>;
};

/**
 * 实验试次数据
 */
export interface TrialData {
  trialNumber: number;
  stimulusType: string;
  stimulus: string;
  correctKey: number;
  response?: ReactionTimeData;
  correct?: boolean;
  timestamp: number;
}

/**
 * 被试信息
 */
export interface ParticipantInfo {
  id: string;
  age?: number;
  gender?: string;
  [key: string]: any;
}

/**
 * 实验管理器类
 */
export class ExperimentManager {
  private reactionBox: ReactionBox;
  private participantInfo: ParticipantInfo | null = null;
  private trials: TrialData[] = [];
  private currentTrial: number = 0;
  private experimentStartTime: number = 0;
  private saveDirectoryHandle: DirectoryHandleLike | null = null;
  
  constructor(reactionBox: ReactionBox) {
    this.reactionBox = reactionBox;
  }
  
  /**
   * 设置被试信息
   */
  setParticipantInfo(info: ParticipantInfo): void {
    this.participantInfo = info;
  }
  
  /**
   * 获取被试信息
   */
  getParticipantInfo(): ParticipantInfo | null {
    return this.participantInfo;
  }
  
  /**
   * 开始实验
   */
  startExperiment(): void {
    this.experimentStartTime = Date.now();
    this.currentTrial = 0;
    this.trials = [];
  }
  
  /**
   * 记录试次数据
   */
  recordTrial(trial: TrialData): void {
    this.trials.push(trial);
    this.currentTrial++;
  }
  
  /**
   * 获取所有试次数据
   */
  getTrials(): TrialData[] {
    return this.trials;
  }
  
  /**
   * 获取当前试次编号
   */
  getCurrentTrialNumber(): number {
    return this.currentTrial;
  }
  
  /**
   * 导出数据为 CSV 格式
   */
  exportToCSV(): string {
    if (this.trials.length === 0) {
      return '';
    }

    const participantId = this.participantInfo?.id || '';
    const participantAge = this.participantInfo?.age ?? '';
    const participantGender = this.participantInfo?.gender || '';
    const taskType = this.participantInfo?.taskType || '';
    
    // CSV 表头
    const headers = [
      'participant_id',
      'participant_age',
      'participant_gender',
      'task_type',
      'trial_number',
      'stimulus_type',
      'stimulus',
      'correct_key',
      'response_key',
      't1',
      't2',
      'press_duration',
      'software_rt',
      'system_delay',
      'correct',
      'timestamp'
    ];
    
    // CSV 数据行
    const rows = this.trials.map(trial => {
      return [
        participantId,
        participantAge,
        participantGender,
        taskType,
        trial.trialNumber,
        trial.stimulusType,
        trial.stimulus,
        trial.correctKey,
        trial.response?.key || '',
        trial.response?.t1 || '',
        trial.response?.t2 || '',
        trial.response?.pressDuration || '',
        trial.response?.softwareRT.toFixed(2) || '',
        trial.response?.systemDelay.toFixed(2) || '',
        trial.correct !== undefined ? (trial.correct ? '1' : '0') : '',
        trial.timestamp
      ].map(value => this.escapeCsvValue(value)).join(',');
    });
    
    return [headers.join(','), ...rows].join('\n');
  }
  
  /**
   * 下载实验数据
   */
  async downloadData(filename?: string): Promise<{ path: string; method: 'filesystem' | 'download' } | null> {
    const csv = this.exportToCSV();
    if (!csv) {
      console.warn('没有数据可以下载');
      return null;
    }
    
    const targetFilename = filename || this.getDefaultFilename();
    const csvWithBom = '\ufeff' + csv;
    const savedPath = await this.saveToCurrentDirectory(targetFilename, csvWithBom);

    if (savedPath) {
      return {
        path: savedPath,
        method: 'filesystem'
      };
    }

    const blob = new Blob([csvWithBom], { type: 'text/csv;charset=utf-8;' }); // 添加 BOM 以支持中文
    const link = document.createElement('a');
    const objectUrl = URL.createObjectURL(blob);
    link.href = objectUrl;
    link.download = targetFilename;
    link.click();
    setTimeout(() => URL.revokeObjectURL(objectUrl), 0);
    return {
      path: targetFilename,
      method: 'download'
    };
  }
  
  /**
   * 获取反应盒实例
   */
  getReactionBox(): ReactionBox {
    return this.reactionBox;
  }

  private escapeCsvValue(value: unknown): string {
    const text = value === undefined || value === null ? '' : String(value);
    if (/[",\r\n]/.test(text)) {
      return `"${text.replace(/"/g, '""')}"`;
    }
    return text;
  }

  private getDefaultFilename(): string {
    return `experiment_${this.participantInfo?.id || 'unknown'}_${Date.now()}.csv`;
  }

  private async saveToCurrentDirectory(filename: string, contents: string): Promise<string | null> {
    const directoryPicker = (window as DirectoryPickerWindow).showDirectoryPicker;
    if (!directoryPicker) {
      return null;
    }

    try {
      if (!this.saveDirectoryHandle) {
        this.saveDirectoryHandle = await directoryPicker({ mode: 'readwrite' });
      }

      const fileHandle = await this.saveDirectoryHandle.getFileHandle(filename, { create: true });
      const writable = await fileHandle.createWritable();
      await writable.write(contents);
      await writable.close();
      return `./${filename}`;
    } catch (error) {
      if (error instanceof DOMException && error.name === 'AbortError') {
        return null;
      }

      console.warn('保存到当前文件夹失败，回退为浏览器下载：', error);
      this.saveDirectoryHandle = null;
      return null;
    }
  }
  
  /**
   * 计算正确率
   */
  calculateAccuracy(): number {
    if (this.trials.length === 0) return 0;
    const correctTrials = this.trials.filter(t => t.correct === true).length;
    return (correctTrials / this.trials.length) * 100;
  }
  
  /**
   * 计算平均反应时（只计算正确试次）
   */
  calculateMeanRT(): number {
    const correctTrials = this.trials.filter(t => t.correct === true && t.response);
    if (correctTrials.length === 0) return 0;
    
    const sum = correctTrials.reduce((acc, t) => acc + (t.response!.t1 || 0), 0);
    return sum / correctTrials.length;
  }

  /**
   * 获取实验统计信息
   */
  getStatistics(): {
    totalTrials: number;
    respondedTrials: number;
    correctTrials: number;
    timeoutTrials: number;
    durationMs: number;
  } {
    const totalTrials = this.trials.length;
    const respondedTrials = this.trials.filter(t => !!t.response).length;
    const correctTrials = this.trials.filter(t => t.correct === true).length;
    const timeoutTrials = this.trials.filter(t => !t.response).length;
    const durationMs = this.experimentStartTime > 0 ? Date.now() - this.experimentStartTime : 0;

    return {
      totalTrials,
      respondedTrials,
      correctTrials,
      timeoutTrials,
      durationMs
    };
  }
}
