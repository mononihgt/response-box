function decision = run_pretest_basic(sp, portName, deviceId)
%RUN_PRETEST_BASIC Pretest window shown before the formal experiment.

decision = "";

state = "connect"; % connect -> testing -> stopped
statusText = "已连接，可开始测试";
statusColor = [0, 0, 0];
fontName = local_ui_font_name();
pretestBuffer = uint8([]);
measurementStart = [];

fig = figure( ...
    'Name', '反应盒调试', ...
    'Color', [0.85, 0.90, 0.95], ...
    'MenuBar', 'none', ...
    'ToolBar', 'none', ...
    'NumberTitle', 'off', ...
    'Position', [160, 80, 1100, 660], ...
    'Resize', 'off', ...
    'CloseRequestFcn', @(~,~)on_close());

uicontrol(fig, ...
    'Style', 'text', ...
    'Position', [170, 560, 760, 32], ...
    'String', sprintf('当前反应盒端口号：%s', portName), ...
    'BackgroundColor', get(fig, 'Color'), ...
    'ForegroundColor', [0.25, 0.25, 0.25], ...
    'FontSize', 18, ...
    'FontName', fontName, ...
    'HorizontalAlignment', 'center');

uicontrol(fig, ...
    'Style', 'text', ...
    'Position', [170, 520, 760, 32], ...
    'String', sprintf('当前反应盒序列号：%s', deviceId), ...
    'BackgroundColor', get(fig, 'Color'), ...
    'ForegroundColor', [0.25, 0.25, 0.25], ...
    'FontSize', 18, ...
    'FontName', fontName, ...
    'HorizontalAlignment', 'center');

statusAxes = axes( ...
    'Parent', fig, ...
    'Units', 'pixels', ...
    'Position', [150, 190, 800, 250], ...
    'Color', get(fig, 'Color'), ...
    'XColor', 'none', ...
    'YColor', 'none', ...
    'XTick', [], ...
    'YTick', [], ...
    'XLim', [0, 1], ...
    'YLim', [0, 1], ...
    'Visible', 'off');

statusLabel = text(statusAxes, 0.5, 0.5, '', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', 30, ...
    'FontWeight', 'bold', ...
    'FontName', fontName, ...
    'Interpreter', 'none', ...
    'Color', statusColor);

btnExit = local_make_button(fig, "退出测试", [160, 55, 200, 64], fontName, @on_exit);
btnStart = local_make_button(fig, "开始测试", [740, 55, 200, 64], fontName, @on_start);
btnStop = local_make_button(fig, "停止测试", [450, 55, 200, 64], fontName, @on_stop);
btnContinue = local_make_button(fig, "继续测试", [450, 55, 200, 64], fontName, @on_continue);
btnEnter = local_make_button(fig, "进入实验", [740, 55, 200, 64], fontName, @on_enter);

local_apply_status(statusLabel, statusText, statusColor);
local_update_buttons();

while isvalid(fig) && strlength(decision) == 0
    drawnow limitrate;
    if ~isvalid(fig)
        break;
    end

    if state == "testing"
        [resp, pretestBuffer] = local_poll_pretest_response(sp, pretestBuffer, measurementStart);
        if ~isempty(resp)
            statusText = sprintf('%s\n按下：%d ms\n松开：%d ms\n系统误差：%.1f ms', ...
                rbx.util.decode_key_name(resp.key), round(resp.t1), round(resp.t2), resp.system_delay);
            statusColor = local_key_color(resp.key);
            local_apply_status(statusLabel, statusText, statusColor);
            [pretestBuffer, measurementStart] = local_start_measurement(sp);
        end
        pause(0.005);
    else
        pause(0.03);
    end
end

if strlength(decision) == 0
    decision = "exit";
end

local_stop_measurement(sp);

if isvalid(fig)
    delete(fig);
end

    function on_start(~, ~)
        [pretestBuffer, measurementStart] = local_start_measurement(sp);
        state = "testing";
        statusText = "测试中，请按键……";
        statusColor = [0, 0, 0];
        local_apply_status(statusLabel, statusText, statusColor);
        local_update_buttons();
    end

    function on_stop(~, ~)
        local_stop_measurement(sp);
        pretestBuffer = uint8([]);
        measurementStart = [];
        state = "stopped";
        statusText = "测试已停止，可进入实验";
        statusColor = [0, 0, 0];
        local_apply_status(statusLabel, statusText, statusColor);
        local_update_buttons();
    end

    function on_continue(~, ~)
        [pretestBuffer, measurementStart] = local_start_measurement(sp);
        state = "testing";
        statusText = "测试中，请按键……";
        statusColor = [0, 0, 0];
        local_apply_status(statusLabel, statusText, statusColor);
        local_update_buttons();
    end

    function on_enter(~, ~)
        local_stop_measurement(sp);
        decision = "proceed";
    end

    function on_exit(~, ~)
        local_stop_measurement(sp);
        decision = "exit";
    end

    function on_close()
        local_stop_measurement(sp);
        decision = "exit";
        if isvalid(fig)
            delete(fig);
        end
    end

    function local_update_buttons()
        switch state
            case "connect"
                set(btnExit, 'Visible', 'on', 'Enable', 'on');
                set(btnStart, 'Visible', 'on', 'Enable', 'on');
                set(btnStop, 'Visible', 'off');
                set(btnContinue, 'Visible', 'off');
                set(btnEnter, 'Visible', 'off');
            case "testing"
                set(btnExit, 'Visible', 'off');
                set(btnStart, 'Visible', 'off');
                set(btnStop, 'Visible', 'on', 'Enable', 'on');
                set(btnContinue, 'Visible', 'off');
                set(btnEnter, 'Visible', 'off');
            case "stopped"
                set(btnExit, 'Visible', 'on', 'Enable', 'on');
                set(btnStart, 'Visible', 'off');
                set(btnStop, 'Visible', 'off');
                set(btnContinue, 'Visible', 'on', 'Enable', 'on');
                set(btnEnter, 'Visible', 'on', 'Enable', 'on');
        end
    end

end

function [buffer, measurementStart] = local_start_measurement(sp)
local_stop_measurement(sp);
local_discard_input(sp);
measurementStart = tic;
write(sp, uint8([hex2dec('FB'), 0]), "uint8");
buffer = uint8([]);
end

function local_stop_measurement(sp)
try
    if isempty(sp) || ~isvalid(sp)
        return;
    end
    write(sp, uint8([hex2dec('FC'), 0]), "uint8");
    pause(0.005);
    local_discard_input(sp);
catch
    % ignore serial cleanup errors during UI transitions
end
end

function local_discard_input(sp)
try
    flush(sp, "input");
catch
    flush(sp);
end
if sp.NumBytesAvailable > 0
    read(sp, sp.NumBytesAvailable, "uint8");
end
end

function [resp, buffer] = local_poll_pretest_response(sp, buffer, measurementStart)
resp = [];

if isempty(measurementStart)
    return;
end

n = sp.NumBytesAvailable;
if n > 0
    chunk = read(sp, n, "uint8");
    buffer = [buffer, reshape(chunk, 1, [])]; %#ok<AGROW>
end

while numel(buffer) >= 1
    headerIdx = find(buffer == hex2dec('FB'), 1);
    if isempty(headerIdx)
        buffer = uint8([]);
        return;
    end
    if headerIdx > 1
        buffer = buffer(headerIdx:end);
    end
    if numel(buffer) < 8
        return;
    end

    frame = buffer(1:8);
    buffer = buffer(9:end);
    resp = local_parse_pretest_frame(frame, measurementStart);
    if ~isempty(resp)
        return;
    end
end
end

function resp = local_parse_pretest_frame(frame, measurementStart)
resp = [];
if numel(frame) ~= 8 || frame(1) ~= hex2dec('FB') || ~ismember(frame(2), uint8(1:5))
    return;
end

key = double(frame(2));
t1 = double(frame(3)) * 256 + double(frame(4));
t2 = double(frame(5)) * 256 + double(frame(6));
if t2 < t1
    return;
end

softwareRt = toc(measurementStart) * 1000.0;
systemDelay = max(0, softwareRt - t2);
resp = struct( ...
    "key", key, ...
    "t1", t1, ...
    "t2", t2, ...
    "press_duration", t2 - t1, ...
    "software_rt", softwareRt, ...
    "system_delay", systemDelay);
end

function btn = local_make_button(fig, label, pos, fontName, callback)
btn = uicontrol(fig, ...
    'Style', 'pushbutton', ...
    'String', char(label), ...
    'Position', pos, ...
    'BackgroundColor', [0.29, 0.44, 0.65], ...
    'ForegroundColor', [1, 1, 1], ...
    'FontSize', 18, ...
    'FontWeight', 'bold', ...
    'FontName', fontName, ...
    'Callback', callback);
end

function local_apply_status(statusLabel, statusText, statusColor)
lines = cellstr(splitlines(string(statusText)));
if ~isempty(lines) && isempty(lines{end})
    lines(end) = [];
end
set(statusLabel, 'String', lines, 'Color', statusColor);
end

function fontName = local_ui_font_name()
if ismac
    fontName = 'PingFang SC';
else
    fontName = 'Microsoft YaHei';
end
end

function c = local_key_color(key)
switch key
    case 1
        c = [0.10, 0.74, 0.61];
    case 2
        c = [0.16, 0.50, 0.73];
    case 3
        c = [0.91, 0.30, 0.24];
    case 4
        c = [0.95, 0.77, 0.06];
    case 5
        c = [0.60, 0.60, 0.60];
    otherwise
        c = [0, 0, 0];
end
end
