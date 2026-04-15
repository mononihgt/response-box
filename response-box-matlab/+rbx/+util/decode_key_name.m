function name = decode_key_name(keyNum)
%DECODE_KEY_NAME Convert numeric key to human-readable label.

switch keyNum
    case 1
        name = "绿色键";
    case 2
        name = "蓝色键";
    case 3
        name = "红色键";
    case 4
        name = "黄色键";
    case 5
        name = "白色键（退出）";
    otherwise
        name = "未知按键(" + string(keyNum) + ")";
end

end
