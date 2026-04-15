"""
反应盒调试小窗
基于 PsychoPy，独立于实验逻辑
"""

import sys
import time
import threading
import queue
from psychopy import visual, core, event
from .reaction_box import get_reaction_time, decode_key_name

# 字体
FONT = 'PingFang SC' if sys.platform == 'darwin' else 'Microsoft YaHei'


def run_pretest_window(port=None, device_id="0001", connect_in_background=False):
    """
    反应盒按键调试窗口。
    参数：
        port: 反应盒端口（如果为None且connect_in_background=True，则在后台连接）
        device_id: 设备ID
        connect_in_background: 是否在窗口中后台连接反应盒
    返回：
        ('proceed', port) 进入实验，返回端口
        ('exit', None)    退出程序
    """
    pre_win = visual.Window(
        size=(900, 520),
        color=(0.85, 0.9, 0.95),
        units='height',
        fullscr=False,
        allowGUI=True,
        winType='pyglet'
    )
    mouse = event.Mouse(win=pre_win, visible=True)

    # 顶部信息（居中对齐，灰色小号）
    port_text = visual.TextStim(
        pre_win,
        text=f"当前反应盒端口号：{port if port else '连接中...'}",
        pos=(0, 0.42),
        anchorHoriz='center',
        color=(0.3, 0.3, 0.3),
        height=0.04,
        font=FONT,
        wrapWidth=1.6
    )
    id_text = visual.TextStim(
        pre_win,
        text=f"当前反应盒序列号：{device_id if device_id else '连接中...'}",
        pos=(0, 0.34),
        anchorHoriz='center',
        color=(0.3, 0.3, 0.3),
        height=0.04,
        font=FONT,
        wrapWidth=1.6
    )

    initial_status = "正在连接反应盒..." if connect_in_background else "已连接，可开始测试"
    status_stim = visual.TextStim(pre_win, text=initial_status, pos=(0, 0.05),
                                  color='black', height=0.07, font=FONT, wrapWidth=1.6, bold=True)

    def make_button(label, center, width=0.4, height=0.12, enabled=True):
        rect = visual.Rect(pre_win, width=width, height=height,
                           lineColor="#4a6fa5", fillColor="#4a6fa5" if enabled else "#9aa8b5",
                           pos=center, opacity=1)
        text = visual.TextStim(pre_win, text=label, pos=center, color='white',
                               height=0.05, font=FONT)
        return {"rect": rect, "text": text, "enabled": enabled, "center": center, "w": width, "h": height}

    def draw_button(btn):
        btn["rect"].fillColor = "#4a6fa5" if btn["enabled"] else "#9aa8b5"
        btn["rect"].lineColor = "#365b85"
        btn["rect"].draw()
        btn["text"].opacity = 1.0 if btn["enabled"] else 0.5
        btn["text"].draw()

    def is_click(btn):
        if not btn["enabled"]:
            return False
        if not any(mouse.getPressed()):
            return False
        x, y = mouse.getPos()
        cx, cy = btn["center"]
        if abs(x - cx) <= btn["w"] / 2 and abs(y - cy) <= btn["h"] / 2:
            return True
        return False

    # 后台连接线程
    connection_result = {'port': port, 'device_id': device_id, 'connected': not connect_in_background}
    connection_lock = threading.Lock()

    def connection_worker():
        """后台连接反应盒"""
        from .serial_utils import auto_find_reaction_box, check_reaction_box
        import time as time_module
        start_time = time_module.time()
        try:
            found_port = auto_find_reaction_box()
            if found_port:
                dev_ok, dev_id = check_reaction_box(found_port)
                elapsed = time_module.time() - start_time
                with connection_lock:
                    connection_result['port'] = found_port
                    connection_result['device_id'] = dev_id if dev_ok else "未知"
                    connection_result['connected'] = True
                    connection_result['elapsed'] = elapsed
                print(f"\n反应盒连接成功！耗时 {elapsed:.1f} 秒")
            else:
                with connection_lock:
                    connection_result['connected'] = False
                    connection_result['error'] = "未找到反应盒"
        except Exception as e:
            with connection_lock:
                connection_result['connected'] = False
                connection_result['error'] = str(e)
            print(f"\n连接失败: {e}")

    # 启动后台连接（如果需要）
    if connect_in_background:
        connection_thread = threading.Thread(target=connection_worker, daemon=True)
        connection_thread.start()

    # 后台线程：阻塞等待按键，减小漏按
    data_q = queue.Queue()
    running_flag = threading.Event()
    stop_flag = threading.Event()

    def worker_loop():
        consecutive_errors = 0
        while running_flag.is_set() and not stop_flag.is_set():
            try:
                current_port = connection_result.get('port')
                if current_port:
                    result = get_reaction_time(current_port, timeout=0.5, show_prompt=False, show_errors=False)
                    if result:
                        data_q.put(result)
                        consecutive_errors = 0  # 重置错误计数
                    else:
                        consecutive_errors += 1
                        if consecutive_errors > 3:
                            # 连续失败太多次，休眠一会儿
                            time.sleep(0.5)
            except Exception as e:
                consecutive_errors += 1
                if consecutive_errors > 10:
                    # 如果连续错误超过10次，停止尝试
                    print(f"\n测试线程错误过多，已停止: {e}")
                    break
                time.sleep(0.1)  # 发生错误时短暂休眠

    def stop_worker(wait_timeout=1.5):
        nonlocal worker_thread
        stop_flag.set()
        running_flag.clear()
        if worker_thread and worker_thread.is_alive():
            worker_thread.join(timeout=wait_timeout)
        stopped = not (worker_thread and worker_thread.is_alive())
        if stopped:
            worker_thread = None
        return stopped

    def clear_pending_results():
        while not data_q.empty():
            try:
                data_q.get_nowait()
            except queue.Empty:
                break

    state = "connect"  # connect -> testing -> stopped
    decision = None
    worker_thread = None

    # 按钮布局（停止阶段居中对称）
    # 如果正在连接，禁用开始测试按钮
    btn_exit = make_button("退出测试", (-0.45, -0.35))
    btn_start = make_button("开始测试", (0.45, -0.35), enabled=not connect_in_background)
    btn_stop = make_button("停止测试", (0.0, -0.35))
    btn_continue = make_button("继续测试", (0.0, -0.35))
    btn_go = make_button("进入实验", (0.45, -0.35), enabled=False)  # 初始禁用
    btn_exit2 = make_button("退出测试", (-0.45, -0.35))

    color_map = {
        1: "#1abc9c",
        2: "#2980b9",
        3: "#e74c3c",
        4: "#f1c40f",
        5: "#999999"
    }

    while True:
        pre_win.flip(clearBuffer=True)
        
        # 检查连接状态并更新UI
        with connection_lock:
            is_connected = connection_result['connected']
            current_port = connection_result.get('port')
            current_device_id = connection_result.get('device_id', '未知')
            
        if connect_in_background and is_connected and state == "connect":
            # 连接成功，更新UI
            port_text.text = f"当前反应盒端口号：{current_port}"
            id_text.text = f"当前反应盒序列号：{current_device_id}"
            status_stim.text = "反应盒已连接，可开始测试"
            status_stim.color = "green"
            btn_start['enabled'] = True
            connect_in_background = False  # 只更新一次
        elif connect_in_background and not is_connected:
            # 检查是否有错误
            error_msg = connection_result.get('error')
            if error_msg:
                status_stim.text = f"连接失败：{error_msg}"
                status_stim.color = "red"
                btn_start['enabled'] = False
        
        port_text.draw()
        id_text.draw()
        status_stim.draw()

        if state == "connect":
            draw_button(btn_exit)
            draw_button(btn_start)
            if is_click(btn_exit):
                decision = "exit"
                break
            if is_click(btn_start) and is_connected:
                state = "testing"
                status_stim.text = "测试中，请按键……"
                status_stim.color = "black"
                clear_pending_results()
                stop_flag.clear()
                running_flag.set()
                worker_thread = threading.Thread(target=worker_loop, daemon=True)
                worker_thread.start()
                mouse.clickReset()

        elif state == "testing":
            draw_button(btn_stop)
            if is_click(btn_stop):
                status_stim.text = "正在释放反应盒，请稍候..."
                status_stim.color = "black"
                port_text.draw()
                id_text.draw()
                status_stim.draw()
                draw_button(btn_stop)
                pre_win.flip()
                if stop_worker():
                    state = "stopped"
                    status_stim.text = "测试已停止，可进入实验"
                    status_stim.color = "black"
                else:
                    status_stim.text = "反应盒仍在释放中，请再试一次"
                    status_stim.color = "red"
                mouse.clickReset()
                continue
            else:
                while not data_q.empty():
                    result = data_q.get()
                    key = result['key']
                    status_stim.text = (
                        f"{decode_key_name(key)}\n"
                        f"按键: {result['t1']} ms\n"
                        f"松键: {result['t2']} ms\n"
                        f"系统误差: {result['system_delay']:.1f} ms"
                    )
                    status_stim.color = color_map.get(key, "black")

        elif state == "stopped":
            # 只有在测试过后才启用进入实验按钮
            btn_go['enabled'] = True
            draw_button(btn_exit2)
            draw_button(btn_continue)
            draw_button(btn_go)
            if is_click(btn_exit2):
                decision = "exit"
                break
            if is_click(btn_continue):
                state = "testing"
                status_stim.text = "测试中，请按键……"
                status_stim.color = "black"
                clear_pending_results()
                stop_flag.clear()
                running_flag.set()
                worker_thread = threading.Thread(target=worker_loop, daemon=True)
                worker_thread.start()
                mouse.clickReset()
            if is_click(btn_go):
                decision = "proceed"
                break

        # 防止连击
        if any(mouse.getPressed()):
            core.wait(0.15)

    stop_worker()
    
    # 等待连接线程停止（如果还在运行）
    if 'connection_thread' in locals():
        connection_thread.join(timeout=1.0)
    
    # 给串口一点时间关闭
    time.sleep(0.2)
    
    pre_win.close()
    
    # 返回决定和端口信息
    if decision == "proceed":
        return (decision, connection_result.get('port'))
    else:
        return (decision, None)
