function [portName, deviceId] = auto_find_reaction_box(baudRate, verbose)
%AUTO_FIND_REACTION_BOX Automatically detect response-box serial port.

if nargin < 1 || isempty(baudRate)
    baudRate = 115200;
end
if nargin < 2 || isempty(verbose)
    verbose = true;
end

portName = "";
deviceId = "";

ports = string(serialportlist("available"));
if isempty(ports)
    if verbose
        fprintf("错误：未找到任何可用串口。\n");
    end
    return;
end

preferredMask = contains(lower(ports), "usbserial") ...
    | contains(lower(ports), "wchusbserial") ...
    | contains(lower(ports), "ch34");

scanOrder = [ports(preferredMask), ports(~preferredMask)];

for i = 1:numel(scanOrder)
    currentPort = scanOrder(i);
    [ok, id, errMsg] = rbx.serial.check_reaction_box(currentPort, baudRate);
    if ok
        portName = currentPort;
        deviceId = id;
        if verbose
            fprintf("✓ 成功连接到反应盒：%s (设备ID: %s)\n", portName, deviceId);
        end
        return;
    end
    if verbose
        fprintf("  %s: %s\n", currentPort, errMsg);
    end
end

if verbose
    fprintf("✗ 未找到反应盒。\n");
end

end

