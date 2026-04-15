/**
 * Stroop 任务实现
 * 经典的颜色-词冲突实验
 */

import { ExperimentManager } from './ExperimentManager';

export type StroopCondition = 'congruent' | 'incongruent';

export interface StroopStimulus {
  word: string;
  color: string;
  condition: StroopCondition;
  correctKey: number;
}

export interface StroopConfig {
  trialsPerCondition: number;
  maskDuration: number;          // 掩蔽刺激持续时间 (ms)
  fixationDuration: number;      // 注视点持续时间 (ms)
  stimulusDuration: number;       // 刺激呈现时间 (ms)，0 表示等待反应
  responseTimeout: number;        // 反应超时 (ms)
  feedbackDuration: number;       // 反馈持续时间 (ms)
  interTrialInterval: number;     // 试次间间隔 (ms)
  taskType: 'color' | 'word';
  keyMapping: { red: number; green: number };
}

type ColorName = 'red' | 'green';

const keyLabels: Record<number, string> = {
  1: '绿色键',
  2: '蓝色键',
  3: '红色键',
  4: '黄色键',
  5: '白键'
};

export class StroopTask {
  private experimentManager: ExperimentManager;
  private config: StroopConfig;
  private stimuli: StroopStimulus[] = [];
  private currentStimulusIndex = 0;

  private colorDefs: Record<ColorName, { word: string; ink: string }> = {
    red: { word: '红', ink: '#FF0000' },
    green: { word: '绿', ink: '#00FF00' }
  };

  constructor(experimentManager: ExperimentManager, config?: Partial<StroopConfig>) {
    this.experimentManager = experimentManager;
    this.config = {
      trialsPerCondition: config?.trialsPerCondition ?? 10,
      maskDuration: config?.maskDuration ?? 800,
      fixationDuration: config?.fixationDuration ?? 500,
      stimulusDuration: config?.stimulusDuration ?? 0,
      responseTimeout: config?.responseTimeout ?? 5000,
      feedbackDuration: config?.feedbackDuration ?? 500,
      interTrialInterval: config?.interTrialInterval ?? 500,
      taskType: config?.taskType ?? 'color',
      keyMapping: config?.keyMapping ?? { red: 3, green: 1 }
    };
  }

  generateStimuli(): void {
    this.stimuli = [];

    for (let i = 0; i < this.config.trialsPerCondition; i++) {
      this.stimuli.push(this.buildStimulus('red', 'red', 'congruent'));
      this.stimuli.push(this.buildStimulus('green', 'green', 'congruent'));
    }

    for (let i = 0; i < this.config.trialsPerCondition; i++) {
      this.stimuli.push(this.buildStimulus('red', 'green', 'incongruent'));
      this.stimuli.push(this.buildStimulus('green', 'red', 'incongruent'));
    }

    this.shuffleArray(this.stimuli);
    this.currentStimulusIndex = 0;
  }

  private buildStimulus(wordColor: ColorName, inkColor: ColorName, condition: StroopCondition): StroopStimulus {
    const word = this.colorDefs[wordColor].word;
    const color = this.colorDefs[inkColor].ink;
    const correctKey = this.getCorrectKey(wordColor, inkColor);
    return { word, color, condition, correctKey };
  }

  private getCorrectKey(wordColor: ColorName, inkColor: ColorName): number {
    if (this.config.taskType === 'color') {
      return inkColor === 'red' ? this.config.keyMapping.red : this.config.keyMapping.green;
    }
    return wordColor === 'red' ? this.config.keyMapping.red : this.config.keyMapping.green;
  }

  private shuffleArray<T>(array: T[]): void {
    for (let i = array.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [array[i], array[j]] = [array[j], array[i]];
    }
  }

  getNextStimulus(): StroopStimulus | null {
    if (this.currentStimulusIndex >= this.stimuli.length) return null;
    return this.stimuli[this.currentStimulusIndex];
  }

  nextTrial(): void {
    this.currentStimulusIndex++;
  }

  getProgress(): { current: number; total: number; percentage: number } {
    const current = this.currentStimulusIndex;
    const total = this.stimuli.length;
    const percentage = total > 0 ? (current / total) * 100 : 0;
    return { current, total, percentage };
  }

  isFinished(): boolean {
    return this.currentStimulusIndex >= this.stimuli.length;
  }

  getConfig(): StroopConfig {
    return this.config;
  }

  getKeyMapping(): string {
    return `红 → ${keyLabels[this.config.keyMapping.red] ?? `按键 ${this.config.keyMapping.red}`}  |  绿 → ${keyLabels[this.config.keyMapping.green] ?? `按键 ${this.config.keyMapping.green}`}`;
  }

  getColorByKey(key: number) {
    if (key === this.config.keyMapping.red) {
      return { name: '红', hex: this.colorDefs.red.ink, key };
    }
    if (key === this.config.keyMapping.green) {
      return { name: '绿', hex: this.colorDefs.green.ink, key };
    }
    return undefined;
  }

  analyzeStroopEffect(): {
    congruent: { meanRT: number; accuracy: number; count: number };
    incongruent: { meanRT: number; accuracy: number; count: number };
    stroopEffect: number;
  } {
    const trials = this.experimentManager.getTrials();

    const analyze = (condition: StroopCondition) => {
      const filtered = trials.filter(t => t.stimulusType === condition && t.correct && t.response);
      const count = trials.filter(t => t.stimulusType === condition).length;
      const accuracy = count > 0 ? (filtered.length / count) * 100 : 0;
      const meanRT = filtered.length > 0
        ? filtered.reduce((sum, t) => sum + (t.response!.t1 || 0), 0) / filtered.length
        : 0;
      return { meanRT, accuracy, count };
    };

    const congruent = analyze('congruent');
    const incongruent = analyze('incongruent');
    const stroopEffect = incongruent.meanRT - congruent.meanRT;

    return { congruent, incongruent, stroopEffect };
  }
}
