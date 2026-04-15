function decision = run_pretest_window(sp, portName, deviceId, cfg)
%RUN_PRETEST_WINDOW Simple pretest UI before formal experiment.
%
% Controls:
%   T      Start key test
%   S      Stop key test
%   SPACE  Enter formal experiment (enabled after at least one key event)
%   ESC    Exit

decision = "exit";
isTesting = false;
testedOnce = false;
statusLine = "按 T 开始测试";
lastEvent = "尚未检测到按键";

screens = Screen('Screens');
screenId = max(screens);
baseRect = [0, 0, 980, 620];
screenRect = Screen('Rect', screenId);
centeredRect = CenterRectOnPointd(baseRect, screenRect(3) / 2, screenRect(4) / 2);
[winPtr, ~] = Screen('OpenWindow', screenId, [220, 230, 245], centeredRect);

cleanupObj = onCleanup(@()local_close_window(winPtr)); %#ok<NASGU>
Screen('TextFont', winPtr, char(cfg.fontName));
KbName('UnifyKeyNames');

while true
    Screen('FillRect', winPtr, [220, 230, 245]);
    Screen('TextSize', winPtr, 34);
    DrawFormattedText(winPtr, '反应盒预检', 'center', 40, [20, 30, 45]);

    Screen('TextSize', winPtr, 24);
    DrawFormattedText(winPtr, sprintf('端口: %s', portName), 80, 130, [35, 45, 60]);
    DrawFormattedText(winPtr, sprintf('设备ID: %s', deviceId), 80, 170, [35, 45, 60]);
    DrawFormattedText(winPtr, sprintf('状态: %s', statusLine), 80, 240, [20, 50, 20]);
    DrawFormattedText(winPtr, sprintf('最近按键: %s', lastEvent), 80, 280, [50, 50, 90]);

    controls = [ ...
        "T: 开始测试", ...
        "S: 停止测试", ...
        "Space: 进入正式实验（至少检测1次按键后可用）", ...
        "Esc: 退出"];
    y = 360;
    for i = 1:numel(controls)
        DrawFormattedText(winPtr, char(controls(i)), 80, y, [40, 55, 80]);
        y = y + 40;
    end

    if testedOnce
        DrawFormattedText(winPtr, '已满足进入实验条件', 80, 540, [0, 100, 40]);
    else
        DrawFormattedText(winPtr, '请先完成至少一次按键测试', 80, 540, [130, 80, 0]);
    end

    Screen('Flip', winPtr);

    if isTesting
        [resp, ~] = rbx.serial.get_reaction_time(sp, 0.2, false, false);
        if ~isempty(resp)
            testedOnce = true;
            keyName = rbx.util.decode_key_name(resp.key);
            lastEvent = sprintf('%s | t1=%d ms | t2=%d ms | delay=%.1f ms', ...
                keyName, round(resp.t1), round(resp.t2), resp.system_delay);
            statusLine = "测试中";
        end
    else
        pause(0.03);
    end

    [isDown, ~, keyCode] = KbCheck;
    if ~isDown
        continue;
    end

    if keyCode(KbName('ESCAPE'))
        decision = "exit";
        break;
    elseif keyCode(KbName('t'))
        isTesting = true;
        statusLine = "测试中（按 S 停止）";
    elseif keyCode(KbName('s'))
        isTesting = false;
        statusLine = "测试已停止";
    elseif keyCode(KbName('space')) && testedOnce
        decision = "proceed";
        break;
    end

    WaitSecs(0.15);
end

end

function local_close_window(winPtr)
try
    if ~isempty(winPtr) && Screen('WindowKind', winPtr) >= 0
        Screen('Close', winPtr);
    end
catch
    % Ignore cleanup errors.
end
end

