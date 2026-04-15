function [ok, deviceId, errMsg] = check_reaction_box(portName, baudRate)
%CHECK_REACTION_BOX Check whether a serial port responds as response box.

if nargin < 2 || isempty(baudRate)
    baudRate = 115200;
end

ok = false;
deviceId = "";
errMsg = "";
sp = [];

try
    sp = serialport(portName, baudRate, "Timeout", 1.0);
    cleanupObj = onCleanup(@()local_close_serial(sp)); %#ok<NASGU>

    flush(sp);
    write(sp, uint8([hex2dec('5A'), 0]), "uint8");

    deadline = tic;
    frame = uint8([]);
    while toc(deadline) < 1.0
        n = sp.NumBytesAvailable;
        if n > 0
            chunk = read(sp, n, "uint8");
            frame = [frame, reshape(chunk, 1, [])]; %#ok<AGROW>
            if ~isempty(frame)
                break;
            end
        end
        pause(0.01);
    end

    if isempty(frame)
        errMsg = "无响应";
        return;
    end

    if frame(1) ~= hex2dec('5A')
        errMsg = "响应格式错误";
        return;
    end

    if numel(frame) >= 3
        deviceId = string(sprintf('%02X%02X', frame(2), frame(3)));
    elseif numel(frame) >= 2
        deviceId = string(sprintf('%02X', frame(2)));
    else
        deviceId = string(sprintf('%02X', frame(1)));
    end

    ok = true;
catch ME
    errMsg = string(ME.message);
end

end

function local_close_serial(sp)
if isempty(sp)
    return;
end
try
    if isvalid(sp)
        delete(sp);
    end
catch
    % Ignore cleanup errors.
end
end

