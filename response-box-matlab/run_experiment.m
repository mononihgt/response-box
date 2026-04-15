function run_experiment()
%RUN_EXPERIMENT MATLAB entry point aligned with python experiment flow.
if exist('Screen', 'file') ~= 0
    Screen('Preference', 'SkipSyncTests', 1);
end
cfg = rbx.config.default_config();
[participant, cfg, ok] = rbx.ui.collect_experiment_config(cfg);
if ~ok
    fprintf("已取消实验配置，程序结束。\n");
    return;
end

fprintf("\n实验配置：\n");
fprintf("  被试：%s，%s 岁，%s\n", participant.name, participant.age, participant.gender);
if cfg.taskType == "color"
    fprintf("  任务类型：按字体颜色作答\n");
else
    fprintf("  任务类型：按文字内容作答\n");
end
fprintf("  按键映射：红色 -> %s，绿色 -> %s\n\n", ...
    rbx.util.decode_key_name(cfg.keyMapping.red), ...
    rbx.util.decode_key_name(cfg.keyMapping.green));

ptbInstalled = local_has_psychtoolbox();
hasPTB = ptbInstalled && isfield(cfg, "usePsychtoolbox") && cfg.usePsychtoolbox;
if hasPTB
    fprintf("检测到 Psychtoolbox，使用 PTB 模式。\n");
elseif ptbInstalled
    fprintf("检测到 Psychtoolbox，但配置中已禁用，改用基础图形模式。\n");
else
    fprintf("未检测到 Psychtoolbox，使用基础图形模式。\n");
end

fprintf("\n正在自动检测反应盒...\n");
[portName, deviceId] = rbx.serial.auto_find_reaction_box(cfg.baudRate, true);
if strlength(portName) == 0
    error("未找到反应盒，请检查连接线、串口驱动和访问权限。");
end

sp = serialport(char(portName), cfg.baudRate, "Timeout", max(1, cfg.responseTimeoutMs / 1000));
serialCleanup = onCleanup(@()local_close_serial(sp)); %#ok<NASGU>

fprintf("正在打开预检窗口...\n");
decision = rbx.ui.run_pretest_basic(sp, portName, deviceId);
if decision ~= "proceed"
    fprintf("用户退出预检，程序结束。\n");
    return;
end

stimuli = rbx.experiment.generate_stimuli(cfg.taskType, cfg.keyMapping);

try
    if hasPTB
        [results, meta] = local_run_ptb_mode(sp, stimuli, cfg);
    else
        [results, meta] = local_run_basic_mode(sp, stimuli, cfg);
    end

    if isempty(results)
        fprintf("没有记录到有效试次数据。\n");
        return;
    end

    stats = rbx.experiment.analyze_results(results);
    outFile = rbx.io.export_csv(results, participant, cfg.taskType, cfg.outputDir);

    fprintf("\n数据已导出：%s\n", outFile);
    fprintf("记录试次数：%d\n", numel(results));

    fprintf("\n============================================================\n");
    fprintf("实验结束\n");
    fprintf("总试次数：%d\n", stats.totalTrials);
    fprintf("正确率：%.1f%%\n", stats.accuracy);
    fprintf("一致试次平均反应时：%.1f 毫秒\n", stats.congruent.meanRT);
    fprintf("不一致试次平均反应时：%.1f 毫秒\n", stats.incongruent.meanRT);
    if ~isnan(stats.stroopEffect)
        fprintf("stroop效应：%.1f 毫秒\n", stats.stroopEffect);
    else
        fprintf("stroop效应：无法计算（有效试次不足）\n");
    end
    if meta.aborted
        fprintf("状态：提前结束（%s）\n", meta.abortReason);
    end
    fprintf("============================================================\n");

catch ME
    fprintf(2, "\n实验出错：%s\n", ME.message);
    for i = 1:numel(ME.stack)
        fprintf(2, "  at %s (line %d)\n", ME.stack(i).name, ME.stack(i).line);
    end
    rethrow(ME);
end

end

function [results, meta] = local_run_ptb_mode(sp, stimuli, cfg)
try
    AssertOpenGL;
    PsychDefaultSetup(2);
    screens = Screen('Screens');
    screenId = max(screens);
    [winPtr, winRect] = Screen('OpenWindow', screenId, cfg.windowBackground);
catch ME
    throwAsCaller(MException( ...
        'response_box:PTBOpenWindowFailed', ...
        'Psychtoolbox 无法打开全屏窗口：%s', ...
        ME.message));
end

screenCleanup = onCleanup(@()sca); %#ok<NASGU>

Priority(MaxPriority(winPtr));
priorityCleanup = onCleanup(@()Priority(0)); %#ok<NASGU>

startOk = local_wait_for_start_ptb(winPtr, winRect, sp, cfg);
if ~startOk
    results = struct([]);
    meta = struct("aborted", true, "abortReason", "cancel_before_start");
    return;
end

[results, meta] = rbx.experiment.run_stroop_task(winPtr, winRect, sp, stimuli, cfg);
stats = rbx.experiment.analyze_results(results);
local_show_results_ptb(winPtr, winRect, stats, cfg);
WaitSecs(5);
end

function [results, meta] = local_run_basic_mode(sp, stimuli, cfg)
startOk = local_wait_for_start_basic(sp, cfg);
if ~startOk
    results = struct([]);
    meta = struct("aborted", true, "abortReason", "cancel_before_start");
    return;
end

[results, meta] = rbx.experiment.run_stroop_task_basic(sp, stimuli, cfg);
stats = rbx.experiment.analyze_results(results);
local_show_results_basic(stats, cfg);
end

function startOk = local_wait_for_start_ptb(winPtr, winRect, sp, cfg)
startOk = false;

if cfg.taskType == "word"
    taskDesc = "根据文字内容作答";
else
    taskDesc = "根据字体颜色作答";
end

instructionText = sprintf([ ...
    'stroop任务\n\n' ...
    '%s\n' ...
    '  看到红色目标时按：%s\n' ...
    '  看到绿色目标时按：%s\n\n' ...
    '实验过程中可随时按白键退出\n' ...
    '请尽量又快又准地作答\n\n' ...
    '按任意反应键开始'], ...
    taskDesc, ...
    rbx.util.decode_key_name(cfg.keyMapping.red), ...
    rbx.util.decode_key_name(cfg.keyMapping.green));

Screen('FillRect', winPtr, cfg.windowBackground);
rbx.ptb.draw_text(winPtr, winRect, instructionText, [255, 255, 255], 44, 'center', 'center', cfg.fontName, cfg.windowBackground);
Screen('Flip', winPtr);

fprintf("等待开始按键...\n");

startResult = [];
for attempt = 1:3
    [startResult, ~] = rbx.serial.get_reaction_time(sp, 60, false, attempt == 3);
    if ~isempty(startResult)
        break;
    end
    if attempt < 3
        fprintf("第 %d 次开始信号读取失败，正在重试...\n", attempt);
        WaitSecs(0.5);
    end
end

if isempty(startResult) || startResult.key == cfg.whiteKey
    fprintf("未能获取开始信号，实验结束。\n");
    return;
end

fprintf("实验开始。\n");
startOk = true;
end

function startOk = local_wait_for_start_basic(sp, cfg)
startOk = false;

fig = figure( ...
    "Name", "stroop任务说明", ...
    "Color", [0, 0, 0], ...
    "MenuBar", "none", ...
    "ToolBar", "none", ...
    "NumberTitle", "off", ...
    "Units", "normalized", ...
    "Position", [0, 0, 1, 1], ...
    "Resize", "off");
cleanup = onCleanup(@()local_close_figure(fig)); %#ok<NASGU>

taskDesc = "根据字体颜色作答";
if cfg.taskType == "word"
    taskDesc = "根据文字内容作答";
end

instructionText = sprintf([ ...
    'stroop任务\n\n' ...
    '%s\n' ...
    '  看到红色目标时按：%s\n' ...
    '  看到绿色目标时按：%s\n\n' ...
    '实验过程中可随时按白键退出\n' ...
    '请尽量又快又准地作答\n\n' ...
    '按任意反应键开始'], ...
    taskDesc, ...
    rbx.util.decode_key_name(cfg.keyMapping.red), ...
    rbx.util.decode_key_name(cfg.keyMapping.green));

ax = axes("Parent", fig, "Position", [0, 0, 1, 1], "Visible", "off");
text(ax, 0.5, 0.5, instructionText, "HorizontalAlignment", "center", ...
    "Color", [1, 1, 1], "FontSize", 28, "FontName", "Arial Unicode MS");
drawnow;

fprintf("等待开始按键...\n");
startResult = [];
for attempt = 1:3
    [startResult, ~] = rbx.serial.get_reaction_time(sp, 60, false, attempt == 3);
    if ~isempty(startResult)
        break;
    end
    if attempt < 3
        fprintf("第 %d 次开始信号读取失败，正在重试...\n", attempt);
        pause(0.5);
    end
end

if isempty(startResult) || startResult.key == cfg.whiteKey
    fprintf("未能获取开始信号，实验结束。\n");
    return;
end

fprintf("实验开始。\n");
startOk = true;
end

function local_show_results_ptb(winPtr, winRect, stats, cfg)
lines = local_result_lines(stats);
Screen('FillRect', winPtr, cfg.windowBackground);

y = 140;
for i = 1:numel(lines)
    rbx.ptb.draw_text(winPtr, winRect, char(lines(i)), [255, 255, 255], 48, 'center', y, cfg.fontName, cfg.windowBackground);
    y = y + 80;
end
Screen('Flip', winPtr);
end

function local_show_results_basic(stats, cfg)
fig = figure( ...
    "Name", "实验结果", ...
    "Color", [0, 0, 0], ...
    "MenuBar", "none", ...
    "ToolBar", "none", ...
    "NumberTitle", "off", ...
    "Units", "normalized", ...
    "Position", [0, 0, 1, 1], ...
    "Resize", "off");

ax = axes("Parent", fig, "Position", [0, 0, 1, 1], "Visible", "off");
lines = local_result_lines(stats);
y = 0.78;
for i = 1:numel(lines)
    text(ax, 0.5, y, char(lines(i)), ...
        "HorizontalAlignment", "center", ...
        "Color", [1, 1, 1], ...
        "FontSize", 28, ...
        "FontName", char(cfg.fontName));
    y = y - 0.1;
end
drawnow;
pause(5);
local_close_figure(fig);
end

function lines = local_result_lines(stats)
lines = [ ...
    "实验结束", ...
    "总试次数：" + string(stats.totalTrials), ...
    sprintf("正确率：%.1f%%", stats.accuracy) ...
];

if stats.congruent.count > 0
    lines(end + 1) = sprintf("一致试次平均反应时：%.0f 毫秒", stats.congruent.meanRT); %#ok<AGROW>
end
if stats.incongruent.count > 0
    lines(end + 1) = sprintf("不一致试次平均反应时：%.0f 毫秒", stats.incongruent.meanRT); %#ok<AGROW>
end
if ~isnan(stats.stroopEffect)
    lines(end + 1) = sprintf("stroop效应：%.0f 毫秒", stats.stroopEffect); %#ok<AGROW>
end
end

function tf = local_has_psychtoolbox()
tf = (exist("Screen", "file") ~= 0) ...
    && (exist("DrawFormattedText", "file") ~= 0) ...
    && (exist("KbCheck", "file") ~= 0);
end

function local_close_serial(sp)
try
    if ~isempty(sp) && isvalid(sp)
        delete(sp);
    end
catch
    % ignore
end
end

function local_close_figure(fig)
try
    if ~isempty(fig) && isvalid(fig)
        close(fig);
    end
catch
    % ignore
end
end
