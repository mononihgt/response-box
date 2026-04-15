"""
反应盒核心模块。

提供读取按键反应时数据的核心能力。
"""

import struct
import time

import serial

SERIAL_SETTLE_DELAY = 0.02
STALE_FRAME_MARGIN_MS = 50
VALID_KEYS = {0x01, 0x02, 0x03, 0x04, 0x05}


def _discard_pending_input(ser):
    """Best-effort clear of stale bytes left by previous trials."""
    ser.reset_input_buffer()
    time.sleep(SERIAL_SETTLE_DELAY)

    pending = ser.in_waiting
    if pending > 0:
        ser.read(pending)
        time.sleep(0.005)
        ser.reset_input_buffer()


def _prepare_measurement(ser):
    """Stop previous timing state and clear leftover frames."""
    _discard_pending_input(ser)
    ser.write(b'\xFC\x00')
    ser.flush()
    time.sleep(0.01)
    _discard_pending_input(ser)


def get_reaction_time(port, baud=115200, timeout=10, show_prompt=True, show_errors=True):
    """
    获取详细的反应时数据。

    返回字段:
        key: 按键编号 (1-5)
        t1: 按键按下反应时 (毫秒)
        t2: 按键松开反应时 (毫秒)
        press_duration: 按压持续时间 (毫秒) = t2 - t1
        software_rt: 软件测得的完整反应时 (毫秒)
        system_delay: 系统误差 (毫秒) = software_rt - t2
        ide: 校验值
    """
    if port is None:
        raise RuntimeError("未指定串口！请先运行 auto_find_reaction_box()")

    try:
        with serial.Serial(port, baud, timeout=timeout) as ser:
            stale_retry_count = 0

            while True:
                _prepare_measurement(ser)

                trigger_time = time.perf_counter()
                ser.write(b'\xFB\x00')
                ser.flush()

                if show_prompt:
                    print("等待按键... (按任意反应盒按键)")
                    show_prompt = False

                frame = ser.read(8)
                receive_time = time.perf_counter()
                software_rt = (receive_time - trigger_time) * 1000

                if len(frame) != 8:
                    raise RuntimeError(f"数据不完整，只收到 {len(frame)} 字节")

                if frame[0] != 0xFB:
                    raise RuntimeError(f"帧头错误: 0x{frame[0]:02X} (应为 0xFB)")

                key = frame[1]
                if key not in VALID_KEYS:
                    raise RuntimeError(f"按键编号错误: 0x{key:02X}")

                t1, t2 = struct.unpack('>HH', frame[2:6])
                ide = int.from_bytes(frame[6:], byteorder='big')

                if t2 < t1:
                    raise RuntimeError(f"时间参数异常: t2({t2}) < t1({t1})")

                system_delay = software_rt - t2
                if system_delay < -STALE_FRAME_MARGIN_MS and stale_retry_count < 1:
                    stale_retry_count += 1
                    if show_errors:
                        print("检测到疑似残留旧数据帧，正在重试...")
                    continue

                if system_delay < -STALE_FRAME_MARGIN_MS:
                    raise RuntimeError(
                        f"系统误差异常: {system_delay:.1f} ms，可能读取到了旧数据帧"
                    )

                return {
                    'key': key,
                    't1': t1,
                    't2': t2,
                    'press_duration': t2 - t1,
                    'software_rt': software_rt,
                    'system_delay': system_delay,
                    'ide': ide,
                }

    except serial.SerialException as error:
        if show_errors:
            print(f"串口通信错误: {error}")
        return None
    except RuntimeError as error:
        if show_errors:
            print(f"数据解析错误: {error}")
        return None


def decode_key_name(key_num):
    """将按键编号转换为按键名称。"""
    key_names = {
        1: "绿色键",
        2: "蓝色键",
        3: "红色键",
        4: "黄色键",
        5: "白色键（退出）",
    }
    return key_names.get(key_num, f"未知按键({key_num})")
