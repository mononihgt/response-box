function [results, meta] = run_stroop_task(winPtr, winRect, sp, stimuli, cfg)
%RUN_STROOP_TASK PTB experiment loop aligned to python experiment flow.

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

startTick = tic;
Screen('TextFont', winPtr, char(cfg.fontName));

for trialNum = 1:nTrials
    stim = stimuli(randi(numel(stimuli)));

    local_draw_center(winPtr, winRect, "@@", cfg.maskColor, cfg.maskTextSize, cfg);
    WaitSecs(cfg.maskMs / 1000);

    local_draw_center(winPtr, winRect, "+", cfg.fixationColor, cfg.fixationTextSize, cfg);
    WaitSecs(cfg.fixationMs / 1000);

    local_draw_center(winPtr, winRect, stim.word, colorMap.(stim.color), cfg.stimulusTextSize, cfg);
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

        local_draw_center(winPtr, winRect, "反应超时\n请集中注意力", cfg.feedbackColor.timeout, cfg.feedbackTextSize, cfg);
        WaitSecs(cfg.feedbackMs / 1000);
        Screen('FillRect', winPtr, cfg.windowBackground);
        Screen('Flip', winPtr);
        WaitSecs(cfg.itiMs / 1000);
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

    local_draw_center(winPtr, winRect, feedbackText, feedbackColor, cfg.feedbackTextSize, cfg);
    WaitSecs(cfg.feedbackMs / 1000);

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

    Screen('FillRect', winPtr, cfg.windowBackground);
    Screen('Flip', winPtr);
    WaitSecs(cfg.itiMs / 1000);
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

function local_draw_center(winPtr, winRect, content, color255, textSize, cfg)
textValue = local_text_value(content);
Screen('FillRect', winPtr, cfg.windowBackground);
rbx.ptb.draw_text(winPtr, winRect, textValue, color255, textSize, 'center', 'center', cfg.fontName, cfg.windowBackground);
Screen('Flip', winPtr);
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

function textValue = local_text_value(content)
if isstring(content)
    if ~isscalar(content)
        content = join(content, newline);
    end
    textValue = char(content);
elseif ischar(content)
    textValue = content;
elseif iscellstr(content)
    textValue = strjoin(content, newline);
else
    textValue = char(string(content));
end
end
