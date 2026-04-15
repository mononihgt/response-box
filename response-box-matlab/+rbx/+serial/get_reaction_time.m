function [resp, errMsg] = get_reaction_time(sp, timeoutSec, showPrompt, showErrors)
%GET_REACTION_TIME Read one response frame from the response box.
%
% Response struct fields:
%   key, t1, t2, press_duration, software_rt, system_delay, ide

if nargin < 2 || isempty(timeoutSec)
    timeoutSec = 10;
end
if nargin < 3 || isempty(showPrompt)
    showPrompt = false;
end
if nargin < 4 || isempty(showErrors)
    showErrors = false;
end

serialSettleSec = 0.02;
staleFrameMarginMs = 50;
maxStaleRetries = 1;

resp = [];
errMsg = "";

try
    if isempty(sp) || ~isvalid(sp)
        error("串口未连接。");
    end

    staleRetries = 0;
    while true
        local_prepare_measurement(sp, serialSettleSec);

        triggerStart = tic;
        write(sp, uint8([hex2dec('FB'), 0]), "uint8");

        if showPrompt
            fprintf("等待按键...\n");
            showPrompt = false;
        end

        frame = local_read_exact(sp, 8, timeoutSec);
        softwareRt = toc(triggerStart) * 1000.0;

        if numel(frame) ~= 8
            error("数据不完整，只收到 %d 字节。", numel(frame));
        end
        if frame(1) ~= hex2dec('FB')
            error("帧头错误: 0x%s", dec2hex(frame(1), 2));
        end
        if ~ismember(frame(2), uint8(1:5))
            error("按键编号错误: 0x%s", dec2hex(frame(2), 2));
        end

        key = double(frame(2));
        t1 = double(frame(3)) * 256 + double(frame(4));
        t2 = double(frame(5)) * 256 + double(frame(6));
        ide = double(frame(7)) * 256 + double(frame(8));

        if t2 < t1
            error("时间参数异常: t2(%d) < t1(%d)", t2, t1);
        end

        systemDelay = softwareRt - t2;
        if systemDelay < -staleFrameMarginMs && staleRetries < maxStaleRetries
            staleRetries = staleRetries + 1;
            if showErrors
                fprintf("检测到疑似残留旧数据帧，正在重试...\n");
            end
            continue;
        end
        if systemDelay < -staleFrameMarginMs
            error("系统误差异常: %.1f ms，可能读取到了旧数据帧。", systemDelay);
        end

        resp = struct( ...
            "key", key, ...
            "t1", t1, ...
            "t2", t2, ...
            "press_duration", t2 - t1, ...
            "software_rt", softwareRt, ...
            "system_delay", max(0, systemDelay), ...
            "ide", ide);
        return;
    end
catch ME
    errMsg = string(ME.message);
    if showErrors
        fprintf("读取反应时失败: %s\n", errMsg);
    end
end

end

function local_prepare_measurement(sp, serialSettleSec)
local_discard_pending_input(sp);
write(sp, uint8([hex2dec('FC'), 0]), "uint8");
pause(0.01);
local_discard_pending_input(sp);
pause(serialSettleSec);
local_discard_pending_input(sp);
end

function local_discard_pending_input(sp)
try
    flush(sp, "input");
catch
    flush(sp);
end
pause(0.005);

n = sp.NumBytesAvailable;
if n > 0
    read(sp, n, "uint8");
    try
        flush(sp, "input");
    catch
        flush(sp);
    end
end
end

function frame = local_read_exact(sp, byteCount, timeoutSec)
frame = uint8([]);
deadline = tic;

while numel(frame) < byteCount
    n = sp.NumBytesAvailable;
    if n > 0
        chunk = read(sp, n, "uint8");
        frame = [frame, reshape(chunk, 1, [])]; %#ok<AGROW>
    end

    if numel(frame) >= byteCount
        frame = frame(1:byteCount);
        return;
    end

    if toc(deadline) >= timeoutSec
        error("读取超时（%.2f 秒）", timeoutSec);
    end
    pause(0.001);
end

end
