function decision = run_pretest_cli(sp, portName, deviceId)
%RUN_PRETEST_CLI Command-line pretest fallback when PTB is unavailable.

fprintf("\n========== 反应盒预检（CLI模式） ==========\n");
fprintf("端口: %s\n", portName);
fprintf("设备ID: %s\n", deviceId);
fprintf("命令:\n");
fprintf("  t -> 测试一次按键\n");
fprintf("  p -> 进入正式实验（至少测试成功一次）\n");
fprintf("  q -> 退出程序\n");
fprintf("==========================================\n");

decision = "exit";
testedOnce = false;

while true
    cmd = lower(strtrim(string(input("请输入命令 [t/p/q]: ", "s"))));

    switch cmd
        case "t"
            [resp, errMsg] = rbx.serial.get_reaction_time(sp, 8, false, false);
            if isempty(resp)
                if strlength(errMsg) == 0
                    fprintf("未检测到有效按键。\n");
                else
                    fprintf("测试失败: %s\n", errMsg);
                end
            else
                testedOnce = true;
                fprintf("按键: %s | t1=%d ms | t2=%d ms | delay=%.1f ms\n", ...
                    rbx.util.decode_key_name(resp.key), round(resp.t1), round(resp.t2), resp.system_delay);
            end

        case "p"
            if testedOnce
                decision = "proceed";
                return;
            end
            fprintf("请先执行至少一次成功按键测试（命令 t）。\n");

        case "q"
            decision = "exit";
            return;

        otherwise
            fprintf("无效命令，请输入 t / p / q。\n");
    end
end

end

