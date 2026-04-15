function [results, meta] = run_stroop_task_basic(sp, stimuli, cfg)
%RUN_STROOP_TASK_BASIC Basic-graphics experiment loop aligned to python.

nTrials = cfg.nTrials;
results = repmat(local_empty_trial(), 1, nTrials);
written = 0;

meta = struct();
meta.aborted = false;
meta.abortReason = "";
meta.startAt = char(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss"));
meta.endAt = "";
meta.durationMs = 0;
meta.completedTrials = 0;

colorMap = local_color_map();
expectedKeys = [cfg.keyMapping.red, cfg.keyMapping.green];

fig = local_open_stage_figure();
figCleanup = onCleanup(@()local_close_figure(fig)); %#ok<NASGU>

startTick = tic;
for trialNum = 1:nTrials
    if ~isvalid(fig)
        meta.aborted = true;
        meta.abortReason = "window_closed";
        break;
    end

    stim = stimuli(randi(numel(stimuli)));

    local_draw_basic(fig, "@@", cfg.maskColor, cfg.maskTextSize, "");
    pause(cfg.maskMs / 1000);

    local_draw_basic(fig, "+", cfg.fixationColor, cfg.fixationTextSize, "");
    pause(cfg.fixationMs / 1000);

    local_draw_basic(fig, stim.word, colorMap.(stim.color), cfg.stimulusTextSize, "");
    [resp, ~] = rbx.serial.get_reaction_time(sp, cfg.responseTimeoutMs / 1000, false, false);

    if ~isempty(resp) && resp.key == cfg.whiteKey
        fprintf("\n检测到白键，实验提前结束。\n");
        meta.aborted = true;
        meta.abortReason = "white_key";
        break;
    end

    if isempty(resp)
        fprintf("试次 %d：反应超时\n", trialNum);
        row = local_timeout_row(trialNum, stim);
        written = written + 1;
        results(written) = row;

        local_draw_basic(fig, "反应超时\n请集中注意力", cfg.feedbackColor.timeout, cfg.feedbackTextSize, "");
        pause(cfg.feedbackMs / 1000);
        local_draw_basic(fig, "", cfg.feedbackColor.normal, cfg.stimulusTextSize, "");
        pause(cfg.itiMs / 1000);
        continue;
    end

    isCorrect = (resp.key == stim.correct_key);
    fastResponse = resp.t1 < 200;
    wrongKey = ~ismember(resp.key, expectedKeys);

    row = local_empty_trial();
    row.trial = trialNum;
    row.word = char(stim.word);
    row.color = char(stim.color);
    row.congruent = logical(stim.congruent);
    row.correct_key = stim.correct_key;
    row.response_key = resp.key;
    row.response_name = char(rbx.util.decode_key_name(resp.key));
    row.t1_press = resp.t1;
    row.t2_release = resp.t2;
    row.press_duration = resp.press_duration;
    row.software_rt = resp.software_rt;
    row.key_delay = resp.press_duration;
    row.system_delay = resp.system_delay;
    row.correct = isCorrect;

    if fastResponse
        feedbackText = sprintf("反应过快（小于 200 毫秒）\n反应时：%d 毫秒", round(resp.t1));
        feedbackColor = cfg.feedbackColor.fast;
    elseif wrongKey
        feedbackText = "按键无效，请使用指定按键";
        feedbackColor = cfg.feedbackColor.invalid;
    elseif isCorrect
        feedbackText = sprintf("回答正确\n按下反应时：%d 毫秒\n松开反应时：%d 毫秒", round(resp.t1), round(resp.t2));
        feedbackColor = cfg.feedbackColor.correct;
    else
        feedbackText = "回答错误\n请集中注意力";
        feedbackColor = cfg.feedbackColor.incorrect;
    end

    local_draw_basic(fig, feedbackText, feedbackColor, cfg.feedbackTextSize, "");
    pause(cfg.feedbackMs / 1000);

    fprintf("\n试次 %d：%s（%s）\n", trialNum, row.word, row.color);
    if isCorrect
        fprintf("  结果：正确\n");
    else
        fprintf("  结果：错误\n");
    end
    fprintf("  按下时间（t1）：%d 毫秒\n", round(resp.t1));
    fprintf("  松开时间（t2）：%d 毫秒\n", round(resp.t2));
    fprintf("  按压持续时间：%d 毫秒\n", round(resp.press_duration));
    fprintf("  软件反应时：%.2f 毫秒\n", resp.software_rt);
    fprintf("  按键延迟：%d 毫秒\n", round(resp.press_duration));
    fprintf("  系统延迟：%.2f 毫秒\n", resp.system_delay);

    written = written + 1;
    results(written) = row;

    local_draw_basic(fig, "", cfg.feedbackColor.normal, cfg.stimulusTextSize, "");
    pause(cfg.itiMs / 1000);
end

if written == 0
    results = struct([]);
else
    results = results(1:written);
end

meta.completedTrials = written;
meta.durationMs = toc(startTick) * 1000;
meta.endAt = char(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss"));

end

function fig = local_open_stage_figure()
fig = figure( ...
    "Name", "stroop实验", ...
    "Color", [0, 0, 0], ...
    "MenuBar", "none", ...
    "ToolBar", "none", ...
    "NumberTitle", "off", ...
    "Units", "normalized", ...
    "Position", [0, 0, 1, 1], ...
    "Resize", "off");

ax = axes("Parent", fig, "Position", [0, 0, 1, 1], "Visible", "off");
set(ax, "XLim", [0, 1], "YLim", [0, 1], "Color", [0, 0, 0]);
end

function local_draw_basic(fig, textValue, color255, fontSize, subtitle)
if nargin < 5
    subtitle = "";
end
if ~isvalid(fig)
    return;
end

ax = findobj(fig, "Type", "axes");
if isempty(ax)
    return;
end

cla(ax);
set(fig, "Color", [0, 0, 0]);
set(ax, "Color", [0, 0, 0], "XLim", [0, 1], "YLim", [0, 1], "Visible", "off");

if strlength(string(textValue)) > 0
    text(ax, 0.5, 0.55, char(textValue), ...
        "HorizontalAlignment", "center", ...
        "VerticalAlignment", "middle", ...
        "Color", double(color255) / 255, ...
        "FontSize", fontSize, ...
        "FontName", "Arial Unicode MS");
end

if strlength(string(subtitle)) > 0
    text(ax, 0.5, 0.12, char(subtitle), ...
        "HorizontalAlignment", "center", ...
        "Color", [0.85, 0.85, 0.9], ...
        "FontSize", 18, ...
        "FontName", "Arial Unicode MS");
end

drawnow;
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

function map = local_color_map()
map = struct();
map.red = [255, 0, 0];
map.green = [0, 255, 0];
end

function row = local_timeout_row(trialNum, stim)
row = local_empty_trial();
row.trial = trialNum;
row.word = char(stim.word);
row.color = char(stim.color);
row.congruent = logical(stim.congruent);
row.correct_key = stim.correct_key;
row.response_name = "timeout";
row.correct = false;
end

function row = local_empty_trial()
row = struct( ...
    "trial", NaN, ...
    "word", "", ...
    "color", "", ...
    "congruent", false, ...
    "correct_key", NaN, ...
    "response_key", NaN, ...
    "response_name", "", ...
    "t1_press", NaN, ...
    "t2_release", NaN, ...
    "press_duration", NaN, ...
    "software_rt", NaN, ...
    "key_delay", NaN, ...
    "system_delay", NaN, ...
    "correct", false);
end
