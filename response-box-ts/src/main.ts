/**
 * 主应用程序
 */

import { ReactionBox } from './serial/ReactionBox';
import { isSerialSupported, requestSerialPort } from './serial/SerialUtils';
import { ExperimentManager } from './experiment/ExperimentManager';
import { StroopTask } from './experiment/StroopTask';

// 全局状态
let reactionBox: ReactionBox | null = null;
let experimentManager: ExperimentManager | null = null;
let stroopTask: StroopTask | null = null;
let isExperimentRunning = false;
let isTestRunning = false;
let testRunId = 0;
const keyLabels: Record<number, string> = {
  1: '绿色键',
  2: '蓝色键',
  3: '红色键',
  4: '黄色键',
  5: '白键'
};

// DOM 元素
const $ = (id: string) => document.getElementById(id)!;

function getKeyLabel(key: number): string {
  return keyLabels[key] || `按键 ${key}`;
}

// 页面切换
function showPage(pageId: string) {
  document.querySelectorAll('.page').forEach(page => {
    page.classList.remove('active');
  });
  $(pageId).classList.add('active');
}

// 更新连接状态
function updateConnectionStatus(connected: boolean) {
  const statusBadge = $('connectionStatus');
  const quickActions = $('quickActions');
  
  if (connected) {
    statusBadge.textContent = '已连接';
    statusBadge.className = 'status-badge connected';
    quickActions.classList.remove('hidden');
  } else {
    statusBadge.textContent = '未连接';
    statusBadge.className = 'status-badge disconnected';
    quickActions.classList.add('hidden');
  }
}

// 调试日志
function debugLog(message: string, type: 'info' | 'success' | 'warning' | 'error' = 'info') {
  const logContent = document.getElementById('debugLogContent');
  if (!logContent) return; // 调试面板已移除时直接忽略

  const now = new Date();
  const time = `${now.toLocaleTimeString('zh-CN', { hour12: false })}.${now.getMilliseconds().toString().padStart(3, '0')}`;

  const logEntry = document.createElement('div');
  logEntry.className = `log-entry log-${type}`;
  logEntry.textContent = `[${time}] ${message}`;

  logContent.appendChild(logEntry);
  logContent.scrollTop = logContent.scrollHeight;
}

async function enterFullscreenAndHideCursor() {
  try {
    if (!document.fullscreenElement && document.documentElement.requestFullscreen) {
      await document.documentElement.requestFullscreen();
    }
  } catch (err) {
    debugLog(`进入全屏失败: ${err}`, 'warning');
  }
  document.body.classList.add('hide-cursor');
}

async function exitFullscreenAndShowCursor() {
  document.body.classList.remove('hide-cursor');
  try {
    if (document.fullscreenElement && document.exitFullscreen) {
      await document.exitFullscreen();
    }
  } catch (err) {
    debugLog(`退出全屏失败: ${err}`, 'warning');
  }
}

// 工具函数：sleep
function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// 连接反应盒
async function connectReactionBox() {
  try {
    if (!isSerialSupported()) {
      alert('您的浏览器不支持 Web Serial API！\n\n请使用 Chrome、Edge 或 Opera 浏览器。');
      debugLog('浏览器不支持 Web Serial API', 'error');
      return;
    }

    // 如果已经连接，直接返回
    if (reactionBox && reactionBox.isConnected()) {
      debugLog('反应盒已连接', 'info');
      return;
    }

    debugLog('请求连接串口设备...', 'info');
    const port = await requestSerialPort();
    
    if (!port) {
      debugLog('用户取消了设备选择', 'warning');
      return;
    }

    reactionBox = new ReactionBox();
    await reactionBox.connect(port);
    
    debugLog('反应盒连接成功！', 'success');
    updateConnectionStatus(true);
    
    // 测试连接
    const testResult = await reactionBox.testConnection();
    if (testResult) {
      debugLog('连接测试通过', 'success');
    }
  } catch (error) {
    debugLog(`连接失败: ${error}`, 'error');
    console.error('连接失败:', error);
    alert(`连接失败：${error}`);
    updateConnectionStatus(false);
    reactionBox = null;
  }
}

// 连接测试页面 - 持续监听模式
async function startConnectionTest() {
  if (isTestRunning) {
    return;
  }

  if (!reactionBox || !reactionBox.isConnected()) {
    alert('请先连接反应盒！');
    return;
  }

  const btnStartTest = $('btnStartTest') as HTMLButtonElement;
  const btnStopTest = $('btnStopTest') as HTMLButtonElement;
  const testLogContent = $('testLogContent');

  const runId = ++testRunId;
  isTestRunning = true;
  btnStartTest.classList.add('hidden');
  btnStopTest.classList.remove('hidden');

  let testCount = 0;

  debugLog('开始按键测试... 持续监听中', 'info');

  while (isTestRunning && runId === testRunId) {
    try {
      const data = await reactionBox.getReactionTime(60000);
      
      // 检查是否已停止
      if (!isTestRunning || runId !== testRunId) break;
      testCount++;
      
      const logEntry = document.createElement('div');
      logEntry.className = 'log-entry';
      logEntry.innerHTML = `
        <strong>测试 ${testCount}</strong>: 
        按键 = ${getKeyLabel(data.key)}, 
        反应时 = ${data.t1}ms, 
        按压时长 = ${data.pressDuration}ms
      `;
      
      testLogContent.insertBefore(logEntry, testLogContent.firstChild);
      
      // 限制日志条数（增加到100条避免卡顿）
      while (testLogContent.children.length > 100) {
        testLogContent.removeChild(testLogContent.lastChild!);
      }
      
      debugLog(`按键测试 ${testCount}: ${getKeyLabel(data.key)} - RT=${data.t1}ms`, 'success');
      
    } catch (error) {
      if (isTestRunning && runId === testRunId) {
        debugLog(`测试出错: ${error}`, 'error');
      }
      break;
    }
  }
  
  // 如果循环自然结束，确保更新UI
  if (isTestRunning && runId === testRunId) {
    stopConnectionTest();
  }
}

function stopConnectionTest() {
  const wasRunning = isTestRunning;
  isTestRunning = false;
  testRunId++;
  
  // 立即更新UI，不等待当前的 getReactionTime 完成
  const btnStartTest = $('btnStartTest') as HTMLButtonElement;
  const btnStopTest = $('btnStopTest') as HTMLButtonElement;
  btnStartTest.classList.remove('hidden');
  btnStopTest.classList.add('hidden');
  if (wasRunning) {
    void reactionBox?.stopTiming().catch(error => {
      debugLog(`停止计时失败: ${error}`, 'warning');
    });
  }
  debugLog('按键测试结束', 'info');
}

// 开始实验
async function startExperiment() {
  // 验证被试信息
  const participantId = ($('participantId') as HTMLInputElement).value.trim();
  if (!participantId) {
    alert('请输入被试编号！');
    return;
  }

  const participantAge = ($('participantAge') as HTMLInputElement).value;
  const participantGender = ($('participantGender') as HTMLSelectElement).value;
  const participantTaskType = ($('participantTaskType') as HTMLSelectElement).value as 'color' | 'word';
  const redKey = parseInt(($('redKeyMapping') as HTMLSelectElement).value, 10);
  const greenKey = parseInt(($('greenKeyMapping') as HTMLSelectElement).value, 10);
  const trialsPerCondition = parseInt(($('trialsPerCondition') as HTMLInputElement).value, 10);
  const responseTimeoutMs = parseInt(($('responseTimeoutMs') as HTMLInputElement).value, 10);
  const feedbackDurationMs = parseInt(($('feedbackDurationMs') as HTMLInputElement).value, 10);

  if (redKey === greenKey) {
    alert('红色与绿色不能映射到同一个按键，请重新选择。');
    return;
  }

  if (!Number.isFinite(trialsPerCondition) || trialsPerCondition < 1 || trialsPerCondition > 80) {
    alert('每种条件试次数应在 1-80 之间。');
    return;
  }

  if (!Number.isFinite(responseTimeoutMs) || responseTimeoutMs < 300 || responseTimeoutMs > 10000) {
    alert('反应超时应在 300-10000 ms 之间。');
    return;
  }

  if (!Number.isFinite(feedbackDurationMs) || feedbackDurationMs < 0 || feedbackDurationMs > 3000) {
    alert('反馈时长应在 0-3000 ms 之间。');
    return;
  }

  // 初始化实验
  if (!reactionBox || !reactionBox.isConnected()) {
    alert('请先连接反应盒！');
    return;
  }

  experimentManager = new ExperimentManager(reactionBox);
  experimentManager.setParticipantInfo({
    id: participantId,
    age: participantAge ? parseInt(participantAge) : undefined,
    gender: participantGender || undefined,
    taskType: participantTaskType
  });

  stroopTask = new StroopTask(experimentManager, {
    trialsPerCondition,
    maskDuration: 800,
    fixationDuration: 500,
    stimulusDuration: 0, // 等待反应
    responseTimeout: responseTimeoutMs,
    feedbackDuration: feedbackDurationMs,
    interTrialInterval: 500,
    taskType: participantTaskType,
    keyMapping: { red: redKey, green: greenKey }
  });

  stroopTask.generateStimuli();
  updateInstructionContent(participantTaskType, redKey, greenKey);
  
  debugLog(`实验初始化完成 - 被试: ${participantId}`, 'success');
  
  // 显示实验说明
  $('participantInfo').classList.add('hidden');
  $('instructions').classList.remove('hidden');
}

// 开始 Stroop 任务
async function runStroopTask() {
  if (!stroopTask || !experimentManager) return;

  $('instructions').classList.add('hidden');
  $('experimentRunning').classList.remove('hidden');

  isExperimentRunning = true;
  let abortedByWhiteKey = false;

  await enterFullscreenAndHideCursor();
  
  experimentManager.startExperiment();
  
  debugLog('Stroop 任务开始', 'success');

  const fixation = $('fixation');
  const mask = $('mask');
  const stimulus = $('stimulus');
  const feedback = $('feedback');
  const progressInfo = $('progressInfo');
  const progressFill = $('progressFill');
  const config = stroopTask.getConfig();
  const validResponseKeys = new Set([config.keyMapping.red, config.keyMapping.green]);

  while (!stroopTask.isFinished() && isExperimentRunning) {
    if (!isExperimentRunning) break;
    
    const currentStimulus = stroopTask.getNextStimulus();
    if (!currentStimulus) break;

    const progress = stroopTask.getProgress();
    progressInfo.textContent = `试次: ${progress.current + 1} / ${progress.total}`;
    progressFill.style.width = `${progress.percentage}%`;

    try {
      // 1. 掩蔽刺激
      mask.textContent = Math.random() < 0.5 ? '@@' : '##';
      mask.classList.remove('hidden');
      fixation.classList.add('hidden');
      stimulus.classList.add('hidden');
      feedback.classList.add('hidden');
      await sleep(config.maskDuration);

      // 2. 注视点
      mask.classList.add('hidden');
      fixation.classList.remove('hidden');
      stimulus.classList.add('hidden');
      feedback.classList.add('hidden');
      await sleep(config.fixationDuration);

      // 3. 呈现刺激
      fixation.classList.add('hidden');
      stimulus.textContent = currentStimulus.word;
      stimulus.style.color = currentStimulus.color;
      stimulus.classList.remove('hidden');
      
      // 等待一小段时间确保刺激显示
      await sleep(50);

      const responseData = await reactionBox!.getReactionTime(config.responseTimeout);

      if (responseData.key === 5) {
        // 白键退出
        experimentManager.recordTrial({
          trialNumber: progress.current + 1,
          stimulusType: currentStimulus.condition,
          stimulus: currentStimulus.word,
          correctKey: currentStimulus.correctKey,
          response: responseData,
          correct: false,
          timestamp: Date.now()
        });
        abortedByWhiteKey = true;
        isExperimentRunning = false;
        debugLog('检测到白键，实验提前结束', 'warning');
        break;
      }
      
      // 判断正误
      const correct = responseData.key === currentStimulus.correctKey;
      const isFastResponse = responseData.t1 < 200;
      const isInvalidKey = !validResponseKeys.has(responseData.key);
      
      // 记录试次数据
      experimentManager.recordTrial({
        trialNumber: progress.current + 1,
        stimulusType: currentStimulus.condition,
        stimulus: currentStimulus.word,
        correctKey: currentStimulus.correctKey,
        response: responseData,
        correct,
        timestamp: Date.now()
      });

      // 4. 反馈
      stimulus.classList.add('hidden');
      if (isFastResponse) {
        feedback.textContent = `反应过快（<200ms），请保持自然节奏\n反应时: ${responseData.t1} ms`;
        feedback.className = 'feedback fast';
      } else if (isInvalidKey) {
        feedback.textContent = '按错键，请使用指定按键';
        feedback.className = 'feedback invalid';
      } else if (correct) {
        feedback.textContent = `反应正确\n按键反应时为 ${responseData.t1} ms\n松键反应时为 ${responseData.t2} ms`;
        feedback.className = 'feedback correct';
      } else {
        feedback.textContent = '反应错误，请集中注意';
        feedback.className = 'feedback incorrect';
      }
      feedback.classList.remove('hidden');
      await sleep(config.feedbackDuration);

      debugLog(`试次 ${progress.current + 1}: ${correct ? '正确' : '错误'} - RT=${responseData.t1}ms`, correct ? 'success' : 'warning');

    } catch (error) {
      debugLog(`试次 ${progress.current + 1}: 超时或错误 - ${error}`, 'error');
      console.error('试次错误:', error);
      
      // 记录超时
      experimentManager.recordTrial({
        trialNumber: progress.current + 1,
        stimulusType: currentStimulus.condition,
        stimulus: currentStimulus.word,
        correctKey: currentStimulus.correctKey,
        timestamp: Date.now()
      });

      mask.classList.add('hidden');
      stimulus.classList.add('hidden');
      feedback.textContent = '反应超时，请集中注意！';
      feedback.className = 'feedback timeout';
      feedback.classList.remove('hidden');
      await sleep(config.feedbackDuration);
    }

    // 5. 试次间间隔
    feedback.classList.add('hidden');
    await sleep(config.interTrialInterval);

    stroopTask.nextTrial();
  }

  finishExperiment(abortedByWhiteKey);
}

function finishExperiment(aborted = false) {
  isExperimentRunning = false;
  exitFullscreenAndShowCursor();

  $('experimentRunning').classList.add('hidden');
  $('experimentFinished').classList.remove('hidden');

  if (experimentManager) {
    const stats = experimentManager.getStatistics();
    const accuracy = experimentManager.calculateAccuracy();
    const stroopAnalysis = stroopTask ? stroopTask.analyzeStroopEffect() : null;
    
    const resultsSummary = $('resultsSummary');
    const abortRow = aborted
      ? `<div class="stat-item"><span class="stat-label">状态：</span><span class="stat-value">白键提前结束</span></div>`
      : '';
    resultsSummary.innerHTML = `
      ${abortRow}
      <div class="stat-item">
        <span class="stat-label">总试次数：</span>
        <span class="stat-value">${stats.totalTrials}</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">正确率：</span>
        <span class="stat-value">${accuracy.toFixed(1)}%</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">有效反应：</span>
        <span class="stat-value">${stats.respondedTrials}</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">平均反应时：</span>
        <span class="stat-value">${experimentManager.calculateMeanRT().toFixed(1)} ms</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">实验时长：</span>
        <span class="stat-value">${Math.round(stats.durationMs / 1000)} s</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">一致条件（RT / 正确率）：</span>
        <span class="stat-value">${stroopAnalysis ? `${stroopAnalysis.congruent.meanRT.toFixed(1)} ms / ${stroopAnalysis.congruent.accuracy.toFixed(1)}%` : '--'}</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">不一致条件（RT / 正确率）：</span>
        <span class="stat-value">${stroopAnalysis ? `${stroopAnalysis.incongruent.meanRT.toFixed(1)} ms / ${stroopAnalysis.incongruent.accuracy.toFixed(1)}%` : '--'}</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">Stroop 效应：</span>
        <span class="stat-value">${stroopAnalysis ? `${stroopAnalysis.stroopEffect.toFixed(1)} ms` : '--'}</span>
      </div>
    `;
    
    debugLog(`实验完成 - 正确率: ${accuracy.toFixed(1)}%`, 'success');
  }
}

function updateInstructionContent(taskType: 'color' | 'word', redKey: number, greenKey: number) {
  const main = $('instructionMain');
  const red = $('instructionRedMapping');
  const green = $('instructionGreenMapping');

  const taskText = taskType === 'color' ? '判断字的颜色' : '判断文字含义';
  main.textContent = taskText;

  const redLabel = taskType === 'color' ? '红色' : '“红”字';
  const greenLabel = taskType === 'color' ? '绿色' : '“绿”字';

  red.textContent = `${redLabel} → 按 ${getKeyLabel(redKey)}`;
  green.textContent = `${greenLabel} → 按 ${getKeyLabel(greenKey)}`;
}

// 页面加载完成后初始化
document.addEventListener('DOMContentLoaded', () => {
  // 检查浏览器支持
  if (!isSerialSupported()) {
    alert('您的浏览器不支持 Web Serial API！\n\n请使用最新版本的 Chrome、Edge 或 Opera 浏览器。');
    debugLog('浏览器不支持 Web Serial API', 'error');
  } else {
    debugLog('应用程序启动', 'success');
    debugLog('浏览器支持 Web Serial API', 'success');
  }

  // 首页按钮
  $('btnConnect').addEventListener('click', connectReactionBox);
  $('btnTest').addEventListener('click', () => showPage('testPage'));
  $('btnExperiment').addEventListener('click', () => {
    showPage('experimentPage');
    $('participantInfo').classList.remove('hidden');
    $('instructions').classList.add('hidden');
    $('experimentRunning').classList.add('hidden');
    $('experimentFinished').classList.add('hidden');
  });

  // 测试页面
  $('btnBackFromTest').addEventListener('click', () => {
    if (isTestRunning) stopConnectionTest();
    showPage('homePage');
  });
  $('btnStartTest').addEventListener('click', startConnectionTest);
  $('btnStopTest').addEventListener('click', stopConnectionTest);
  $('btnStartExperimentFromTest').addEventListener('click', () => {
    if (isTestRunning) stopConnectionTest();
    showPage('experimentPage');
    $('participantInfo').classList.remove('hidden');
    $('instructions').classList.add('hidden');
    $('experimentRunning').classList.add('hidden');
    $('experimentFinished').classList.add('hidden');
  });

  // 实验页面
  $('participantForm').addEventListener('submit', (e) => {
    e.preventDefault();
    startExperiment();
  });
  $('btnBackFromInfo').addEventListener('click', () => showPage('homePage'));
  $('btnBackFromInstructions').addEventListener('click', () => {
    $('instructions').classList.add('hidden');
    $('participantInfo').classList.remove('hidden');
  });
  $('btnStartExperiment').addEventListener('click', runStroopTask);
  $('btnDownloadData').addEventListener('click', async () => {
    if (experimentManager) {
      const result = await experimentManager.downloadData();
      if (!result) {
        debugLog('数据保存已取消', 'warning');
        return;
      }

      const message = result.method === 'filesystem'
        ? `数据已保存到 ${result.path}`
        : `数据已下载为 ${result.path}`;
      debugLog(message, 'success');
    }
  });
  $('btnBackToHome').addEventListener('click', () => {
    showPage('homePage');
    // 重置实验状态
    experimentManager = null;
    stroopTask = null;
  });
});
