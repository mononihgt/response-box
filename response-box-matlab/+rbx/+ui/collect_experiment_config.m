function [participant, cfg, ok] = collect_experiment_config(cfg)
%COLLECT_EXPERIMENT_CONFIG Collect participant and task settings.

participant = struct();
ok = false;

keyLabels = {'绿色键', '蓝色键', '红色键', '黄色键'};
genderLabels = {'男', '女', '其他'};
taskLabels = {'根据颜色按键', '根据文字按键'};
fontName = local_ui_font_name();

dlg = dialog( ...
    'Name', 'Stroop 实验配置', ...
    'Position', [100, 100, 520, 390], ...
    'Color', [0.95, 0.96, 0.99], ...
    'WindowStyle', 'modal');

uiPos = @(y)[30, y, 170, 24];
ctrlPos = @(y)[210, y, 280, 28];

local_label(dlg, uiPos(340), '姓名:', fontName);
nameEdit = uicontrol(dlg, 'Style', 'edit', 'Position', ctrlPos(338), 'String', '', 'FontName', fontName);

local_label(dlg, uiPos(300), '年龄:', fontName);
ageEdit = uicontrol(dlg, 'Style', 'edit', 'Position', ctrlPos(298), 'String', '', 'FontName', fontName);

local_label(dlg, uiPos(260), '性别:', fontName);
genderPopup = uicontrol(dlg, 'Style', 'popupmenu', 'Position', ctrlPos(258), 'String', genderLabels, 'Value', 3, 'FontName', fontName);

local_label(dlg, uiPos(220), '任务类型:', fontName);
taskPopup = uicontrol(dlg, 'Style', 'popupmenu', 'Position', ctrlPos(218), 'String', taskLabels, 'Value', 1, 'FontName', fontName);

local_label(dlg, uiPos(180), '看到红色/"红"字时按:', fontName);
redPopup = uicontrol(dlg, 'Style', 'popupmenu', 'Position', ctrlPos(178), 'String', keyLabels, 'Value', 3, 'FontName', fontName);

local_label(dlg, uiPos(140), '看到绿色/"绿"字时按:', fontName);
greenPopup = uicontrol(dlg, 'Style', 'popupmenu', 'Position', ctrlPos(138), 'String', keyLabels, 'Value', 1, 'FontName', fontName);

uicontrol(dlg, 'Style', 'pushbutton', 'Position', [160, 40, 90, 36], 'String', '取消', ...
    'FontName', fontName, 'Callback', @(~,~)on_cancel());
uicontrol(dlg, 'Style', 'pushbutton', 'Position', [270, 40, 90, 36], 'String', '确定', ...
    'FontName', fontName, 'BackgroundColor', [0.29, 0.44, 0.65], 'ForegroundColor', [1, 1, 1], ...
    'Callback', @(~,~)on_ok());

uiwait(dlg);

    function on_cancel()
        ok = false;
        if isvalid(dlg)
            delete(dlg);
        end
    end

    function on_ok()
        name = strtrim(string(get(nameEdit, 'String')));
        age = strtrim(string(get(ageEdit, 'String')));
        redIdx = get(redPopup, 'Value');
        greenIdx = get(greenPopup, 'Value');
        ageNum = str2double(age);

        if strlength(name) == 0
            errordlg('错误：姓名不能为空！', '配置错误');
            return;
        end
        if strlength(age) == 0
            errordlg('错误：年龄不能为空！', '配置错误');
            return;
        end
        if ~(isfinite(ageNum) && ageNum > 0 && floor(ageNum) == ageNum)
            errordlg('错误：年龄必须是正整数！', '配置错误');
            return;
        end
        if redIdx == greenIdx
            errordlg('错误：红色和绿色不能使用同一个按键！', '配置错误');
            return;
        end

        genderVal = genderLabels{get(genderPopup, 'Value')};
        taskVal = taskLabels{get(taskPopup, 'Value')};

        participant = struct();
        participant.name = char(name);
        participant.age = sprintf('%d', ageNum);
        participant.gender = char(genderVal);
        timestamp = datetime("now");
        participant.date = char(timestamp, "yyyy-MM-dd");
        participant.time = char(timestamp, "HH:mm:ss");

        keyMap = [1, 2, 3, 4];
        cfg.keyMapping = struct("red", keyMap(redIdx), "green", keyMap(greenIdx));
        if strcmp(taskVal, '根据颜色按键')
            cfg.taskType = "color";
        else
            cfg.taskType = "word";
        end

        cfg.nTrials = 12;
        cfg.maskMs = 1000;
        cfg.fixationMs = 500;
        cfg.responseTimeoutMs = 2000;
        cfg.feedbackMs = 1000;
        cfg.itiMs = 1000;

        ok = true;
        drawnow;
        pause(0.05);
        if isvalid(dlg)
            delete(dlg);
        end
    end

end

function local_label(parent, pos, textValue, fontName)
uicontrol(parent, ...
    'Style', 'text', ...
    'Position', pos, ...
    'String', textValue, ...
    'HorizontalAlignment', 'left', ...
    'BackgroundColor', get(parent, 'Color'), ...
    'FontName', fontName);
end

function fontName = local_ui_font_name()
if ismac
    fontName = 'PingFang SC';
else
    fontName = 'Microsoft YaHei';
end
end
