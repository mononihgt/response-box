"""
测试工具模块
==========

提供各种测试功能
"""

import time
import numpy as np
from .serial_utils import list_all_ports, auto_find_reaction_box
from .reaction_box import get_reaction_time, decode_key_name


def test_basic_connection(port=None):
    """
    测试1：基础连接测试
    """
    print("\n" + "=" * 60)
    print("测试1：基础连接测试")
    print("=" * 60)
    
    # 列出所有串口
    list_all_ports()
    
    # 自动查找反应盒
    if port is None:
        port = auto_find_reaction_box()
    
    if port:
        print(f"\n✓ 测试通过：反应盒连接正常 ({port})")
        return True
    else:
        print("\n✗ 测试失败：未找到反应盒")
        return False


def test_key_detection(port):
    """
    测试2：按键检测测试
    """
    print("\n" + "=" * 60)
    print("测试2：按键检测测试")
    print("=" * 60)
    print("\n请依次按下 5 个按键（绿、蓝、红、黄、白）")
    print("按白色键退出测试\n")
    
    test_count = 0
    
    while True:
        test_count += 1
        print(f"\n第 {test_count} 次测试：")
        
        result = get_reaction_time(port)
        
        if result is None:
            print("✗ 获取按键失败！")
            continue
        
        key = result['key']
        key_name = decode_key_name(key)
        print(f"  按键: {key_name}")
        print(f"  按键按下时间 (t1): {result['t1']} ms")
        print(f"  按键松开时间 (t2): {result['t2']} ms")
        print(f"  按压持续时间: {result['press_duration']} ms")
        
        # 白色键退出
        if key == 5:
            print("\n检测到退出键，结束测试")
            break
    
    print("\n✓ 测试完成")


def test_reaction_time(port):
    """
    测试3：反应时测量测试
    """
    print("\n" + "=" * 60)
    print("测试3：反应时测量测试")
    print("=" * 60)
    print("\n将进行10次反应时测试")
    print("听到提示音后，请尽快按下任意按键\n")
    
    reaction_times = []
    
    for i in range(10):
        print(f"\n--- 第 {i+1}/10 次 ---")
        print("准备...")
        time.sleep(np.random.uniform(1, 3))  # 随机等待1-3秒
        
        print("现在！请按键！")
        
        result = get_reaction_time(port, show_prompt=False)
        
        if result is None:
            print("  ✗ 测试失败，跳过")
            continue
        
        reaction_times.append(result['t1'])
        print(f"  反应时: {result['t1']} ms ({decode_key_name(result['key'])})")
    
    # 统计分析
    if reaction_times:
        print("\n" + "-" * 60)
        print("统计结果：")
        print(f"  平均反应时: {np.mean(reaction_times):.2f} ms")
        print(f"  标准差: {np.std(reaction_times):.2f} ms")
        print(f"  最快: {np.min(reaction_times)} ms")
        print(f"  最慢: {np.max(reaction_times)} ms")
        print("-" * 60)
    
    print("\n✓ 测试完成")


def calibrate_system_delay(port):
    """
    测试4：系统延迟校准（手动版）
    
    通过实际按键测量系统差值
    不需要特殊硬件配置
    """
    print("\n" + "=" * 60)
    print("测试4：系统延迟校准（手动版）")
    print("=" * 60)
    print("\n本测试通过真实按键来测量系统差值")
    print("\n测试方法：")
    print("  1. 听到提示后，尽快按下任意按键")
    print("  2. 重复10次，计算平均系统差值")
    print("\n测试原理：")
    print("  - 系统差值 = 软件测量时间 - t2（按键松开时间）")
    print("  - 这个差值代表串口通信和Python处理的延迟")
    print("  - 典型值应该在 10-30 ms 之间")
    
    response = input("\n是否继续？(y/n): ")
    if response.lower() != 'y':
        print("已取消测试")
        return
    
    print("\n正在测试系统延迟...")
    results = []
    
    for i in range(10):
        print(f"\n--- 第 {i+1}/10 次 ---")
        print("准备...")
        time.sleep(np.random.uniform(1, 2))
        print("现在！请按键！")
        
        try:
            result = get_reaction_time(port, show_prompt=False)
            
            if result is not None:
                results.append(result)
                print(f"  t1: {result['t1']} ms")
                print(f"  t2: {result['t2']} ms")
                print(f"  系统差值: {result['system_delay']:.2f} ms")
            else:
                print("  ✗ 获取数据失败，跳过")
        except Exception as e:
            print(f"  ✗ 错误: {e}")
    
    if results:
        system_delays = [r['system_delay'] for r in results]
        software_rts = [r['software_rt'] for r in results]
        t1_values = [r['t1'] for r in results]
        t2_values = [r['t2'] for r in results]
        
        print("\n" + "-" * 60)
        print("校准结果：")
        print(f"  平均 t1: {np.mean(t1_values):.2f} ± {np.std(t1_values):.2f} ms")
        print(f"  平均 t2: {np.mean(t2_values):.2f} ± {np.std(t2_values):.2f} ms")
        print(f"  平均软件反应时: {np.mean(software_rts):.2f} ± {np.std(software_rts):.2f} ms")
        print(f"  ★ 平均系统差值: {np.mean(system_delays):.2f} ± {np.std(system_delays):.2f} ms")
        print("-" * 60)
        print("\n结论：")
        avg_delay = np.mean(system_delays)
        if 5 <= avg_delay <= 50:
            print(f"  ✓ 系统差值正常 ({avg_delay:.2f} ms)")
            print("  - 串口通信和Python处理延迟在合理范围内")
            print("  - 可以放心使用 t1 作为反应时测量值")
        else:
            print(f"  ⚠ 系统差值异常 ({avg_delay:.2f} ms)")
            print("  - 可能的原因：系统负载高、USB延迟等")
            print("  - 建议：关闭其他程序，使用USB 2.0接口")
        print("-" * 60)
    else:
        print("\n✗ 校准失败，未获取到有效数据")
        print("\n可能的原因：")
        print("  - 反应盒连接异常")
        print("  - 超时未按键")
        print("  - 串口通信错误")
    
    print("\n✓ 测试完成")


def test_detailed_parameters(port):
    """
    测试5：详细参数测试
    
    显示反应盒返回的所有时间参数
    """
    print("\n" + "=" * 60)
    print("测试5：详细参数测试")
    print("=" * 60)
    print("\n本测试将显示反应盒返回的所有时间参数：")
    print("  1. t1 - 按键按下反应时（从刺激到按下按键）")
    print("  2. t2 - 按键松开时间（从刺激到松开按键）")
    print("  3. 按压持续时间 - t2 - t1（按键按下到松开的时间）")
    print("  4. 软件系统反应时 - Python程序测量的反应时")
    print("  5. 系统差值 - 软件反应时与t2的差（串口和Python处理延迟）")
    print("\n请按反应盒上的任意按键...\n")
    
    # 使用详细版本的函数
    result = get_reaction_time(port)
    
    if result is None:
        print("✗ 获取数据失败！")
        return
    
    print("\n" + "-" * 60)
    print("反应盒参数详情：")
    print("-" * 60)
    print(f"  按键编号: {result['key']} ({decode_key_name(result['key'])})")
    print(f"  1. t1 (按键按下反应时): {result['t1']} ms")
    print(f"  2. t2 (按键松开时间): {result['t2']} ms")
    print(f"  3. 按压持续时间 (t2-t1): {result['press_duration']} ms")
    print(f"  4. 软件系统反应时: {result['software_rt']:.2f} ms")
    print(f"  5. 系统差值 (软件-t2): {result['system_delay']:.2f} ms")
    print("-" * 60)
    print("\n参数说明：")
    print("  ✓ t1 是主要的反应时测量值（最重要）")
    print("  ✓ t2 包含了按键按下和松开的全部时间")
    print("  ✓ 系统差值是串口通信和Python处理造成的额外延迟")
    print("  ✓ 在实验中应该使用 t1 作为真实反应时")
    print("-" * 60)
    
    print("\n✓ 测试完成")


def demo_simple_experiment(port):
    """
    演示：简单的二择一实验
    """
    print("\n" + "=" * 60)
    print("演示：简单的二择一实验")
    print("=" * 60)
    print("\n实验说明：")
    print("  屏幕会显示数字 1 或 3")
    print("  如果是 1，按绿色键")
    print("  如果是 3，按红色键")
    print("  共 10 次试次\n")
    
    input("准备好后按 Enter 开始...")
    
    results = []
    
    for trial in range(1, 11):
        # 随机生成刺激
        stimulus = np.random.choice([1, 3])
        correct_key = stimulus  # 1对应绿色键，3对应红色键
        
        print(f"\n========== 试次 {trial}/10 ==========")
        print(f"\n  刺激: {stimulus}")
        print(f"  正确按键: {decode_key_name(correct_key)}")
        print()
        
        # 获取详细反应数据
        result = get_reaction_time(port)
        
        if result is None:
            print("  ✗ 未检测到按键，跳过")
            continue
        
        key = result['key']
        t1 = result['t1']
        
        # 判断正误
        is_correct = (key == correct_key)
        
        print(f"\n  你的按键: {decode_key_name(key)}")
        print(f"  结果: {'✓ 正确' if is_correct else '✗ 错误'}")
        print(f"\n  时间参数详情：")
        print(f"    - 按键按下时间 (t1): {result['t1']} ms")
        print(f"    - 按键松开时间 (t2): {result['t2']} ms")
        print(f"    - 按压持续时间: {result['press_duration']} ms")
        print(f"    - 软件系统时间: {result['software_rt']:.2f} ms")
        print(f"    - 系统误差: {result['system_delay']:.2f} ms")
        
        # 记录数据
        results.append({
            'trial': trial,
            'stimulus': stimulus,
            'correct_key': correct_key,
            'response_key': key,
            'reaction_time': t1,
            't1': result['t1'],
            't2': result['t2'],
            'press_duration': result['press_duration'],
            'software_rt': result['software_rt'],
            'system_delay': result['system_delay'],
            'correct': is_correct
        })
    
    # 统计结果
    if results:
        correct_count = sum(1 for r in results if r['correct'])
        accuracy = correct_count / len(results) * 100
        
        correct_rts = [r['reaction_time'] for r in results if r['correct']]
        error_rts = [r['reaction_time'] for r in results if not r['correct']]
        
        print("\n" + "=" * 60)
        print("实验结果统计")
        print("=" * 60)
        print(f"  总试次: {len(results)}")
        print(f"  正确数: {correct_count}")
        print(f"  正确率: {accuracy:.1f}%")
        
        if correct_rts:
            print(f"\n  正确反应时: {np.mean(correct_rts):.2f} ± {np.std(correct_rts):.2f} ms")
        
        if error_rts:
            print(f"  错误反应时: {np.mean(error_rts):.2f} ± {np.std(error_rts):.2f} ms")
        
        print("=" * 60)
    
    print("\n✓ 实验完成")
