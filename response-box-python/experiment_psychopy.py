"""
PsychoPy实验示例 - Stroop任务
=============================

演示如何在PsychoPy中使用反应盒
"""

from psychopy import visual, core, gui
import random
import re
import pandas as pd
from datetime import datetime
from pathlib import Path
import sys
from src import get_reaction_time, decode_key_name
from src.pretest import run_pretest_window


# ==================== 实验参数 ====================

# 反应盒配置
PORT = None  # 自动检测

# 字体（在 macOS 上优先使用系统中文字体，Windows 自动回退）
FONT = 'PingFang SC' if sys.platform == 'darwin' else 'Microsoft YaHei'

# 实验配置（通过GUI设置）
EXP_INFO = {}  # 被试信息
TASK_TYPE = 'color'  # 'color' or 'word'
KEY_MAPPING = {'red': 3, 'green': 1}

# 刺激参数（将根据任务类型动态生成）
STIMULI = []

N_TRIALS = 12  # 试次数
FIXATION_TIME = 0.5  # 注视点时间（秒）
RESPONSE_TIMEOUT = 2.0
WHITE_KEY = 5


def show_config_error(message):
    """Show a small configuration error dialog."""
    error_dlg = gui.Dlg(title="配置错误")
    error_dlg.addText(message)
    error_dlg.addText("请重新输入。")
    error_dlg.show()


def safe_filename_fragment(value):
    """Convert free text to a filename-safe fragment."""
    fragment = re.sub(r'[<>:"/\\|?*\x00-\x1f]+', '_', str(value or '').strip())
    return fragment.strip(' ._') or 'unknown'


def build_balanced_trials(stimuli, n_trials):
    """Build a shuffled trial list with near-uniform stimulus counts."""
    if not stimuli:
        raise ValueError("STIMULI cannot be empty")
    if n_trials <= 0:
        return []

    base_repeats, remainder = divmod(n_trials, len(stimuli))
    trials = list(stimuli) * base_repeats
    if remainder:
        trials.extend(random.sample(stimuli, remainder))
    random.shuffle(trials)
    return trials


# ==================== GUI配置 ====================

def get_experiment_config():
    """通过GUI对话框收集实验配置"""
    while True:  # 循环直到配置有效
        dlg = gui.Dlg(title="Stroop实验配置")
        
        dlg.addField('姓名:', '')
        dlg.addField('年龄:', '')
        dlg.addField('性别:', choices=['男', '女', '其他'])
        dlg.addField('任务类型:', choices=['根据颜色按键', '根据文字按键'])
        dlg.addField('看到红色/"红"字时按:', choices=['🟢 绿色键', '🔵 蓝色键', '🔴 红色键', '🟡 黄色键'])
        dlg.addField('看到绿色/"绿"字时按:', choices=['🟢 绿色键', '🔵 蓝色键', '🔴 红色键', '🟡 黄色键'])
        
        dlg.show()
        if not dlg.OK:
            core.quit()
        
        # 检查姓名和年龄是否为空
        if not dlg.data[0] or not str(dlg.data[0]).strip():
            show_config_error('错误：姓名不能为空！')
            continue
        
        if not dlg.data[1] or not str(dlg.data[1]).strip():
            show_config_error('错误：年龄不能为空！')
            continue

        age_text = str(dlg.data[1]).strip()
        if not age_text.isdigit() or int(age_text) <= 0:
            show_config_error('错误：年龄必须是正整数！')
            continue

        # 检查按键是否相同
        if dlg.data[4] == dlg.data[5]:
            show_config_error('错误：红色和绿色不能使用同一个按键！')
            continue  # 重新显示配置对话框
        
        # 解析结果
        exp_info = {
            'name': dlg.data[0],
            'age': age_text,
            'gender': dlg.data[2],
            'date': datetime.now().strftime('%Y-%m-%d'),
            'time': datetime.now().strftime('%H:%M:%S')
        }
        
        task_type = 'color' if dlg.data[3] == '根据颜色按键' else 'word'
        
        # 转换按键映射
        key_map = {
            '🟢 绿色键': 1,
            '🔵 蓝色键': 2,
            '🔴 红色键': 3,
            '🟡 黄色键': 4
        }
        key_mapping = {
            'red': key_map[dlg.data[4]],
            'green': key_map[dlg.data[5]]
        }
        
        return exp_info, task_type, key_mapping


# 调试窗口逻辑已迁移至 src.pretest.run_pretest_window

# ==================== 初始化 ====================

def setup(port):
    """初始化实验"""
    global PORT, win, text_stim, fixation, instruction, mask_1, mask_2, feedback_stim
    PORT = port
    # 创建窗口，使用 height 坐标系确保不同分辨率下尺寸/间距自适应
    # 在 units='height' 下，高度 1.0 等于窗口高度；文本高度取 0.04~0.12 更稳妥
    win = visual.Window(color=(0, 0, 0), units='height', fullscr=True)
    
    # 创建文字刺激
    text_stim = visual.TextStim(win, text='', color='black', height=0.12, font=FONT, wrapWidth=1.2)
    
    # 注视点
    fixation = visual.TextStim(win, text='+', color='white', height=0.08, font=FONT)
    
    # 视觉掩蔽刺激
    mask_1 = visual.TextStim(win, text="# #", color='white', height=0.12, font=FONT)
    mask_2 = visual.TextStim(win, text="@@", color='white', height=0.12, font=FONT)
    
    # 反馈刺激
    feedback_stim = visual.TextStim(win, text='', color='white', height=0.05, font=FONT, wrapWidth=1.2)
    
    # 动态生成指导语
    task_desc = '看到字的颜色' if TASK_TYPE == 'color' else '看到字的内容'
    red_key_name = decode_key_name(KEY_MAPPING['red'])
    green_key_name = decode_key_name(KEY_MAPPING['green'])
    
    instruction = visual.TextStim(
        win,
        text=f'Stroop任务\n\n'
             f'{task_desc}：\n'
             f'  红 → 按{red_key_name}\n'
             f'  绿 → 按{green_key_name}\n\n'
             f'随时可按白键退出\n\n'
             f'请又快又准地反应\n\n'
             f'按任意键开始',
        color='white',
        height=0.05,
        font=FONT,
        wrapWidth=1.4,
        alignText='center'
    )


def get_reaction_with_timeout(port, timeout=2.0):
    """获取反应时（支持超时和白键退出检测）"""
    # 直接使用原有的 get_reaction_time 函数
    result = get_reaction_time(port, timeout=timeout, show_prompt=False, show_errors=False)
    
    if result is None:
        return None  # 超时或错误
    
    # 检测白键退出
    if result['key'] == WHITE_KEY:
        return {'exit': True}
    
    return result


def run_experiment():
    """运行实验"""
    results = []
    
    # 显示指导语
    instruction.draw()
    win.flip()
    
    # 等待按键开始（必须按键，不会超时自动开始）
    print("等待按键开始实验...")
    
    # 尝试多次连接，防止端口被占用
    start_result = None
    for attempt in range(3):
        start_result = get_reaction_time(PORT, timeout=60, show_prompt=False, show_errors=(attempt == 2))
        if start_result is not None:
            break
        if attempt < 2:
            print(f"第 {attempt + 1} 次尝试失败，稍后重试...")
            core.wait(0.5)
    
    if start_result is None:
        print("错误：无法读取反应盒数据，实验退出")
        print("请检查：")
        print("  1. 反应盒是否正常连接")
        print("  2. COM端口是否被其他程序占用")
        print("  3. 尝试重新插拔反应盒")
        return []
    print("实验开始！\n")
    
    # 隐藏鼠标光标
    win.mouseVisible = False
    
    # 实验循环
    trial_sequence = build_balanced_trials(STIMULI, N_TRIALS)
    for trial_num, stim in enumerate(trial_sequence, start=1):
        # 随机选择刺激
        
        # 视觉掩蔽（清除上一试次残留）
        # mask_1.draw()
        mask_2.draw()
        win.flip()
        core.wait(1.0)  # 掩蔽呈现1秒
        
        # 注视点
        fixation.draw()
        win.flip()
        core.wait(FIXATION_TIME)
        
        # 呈现刺激
        text_stim.text = stim['word']
        text_stim.color = stim['color']
        text_stim.draw()
        win.flip()
        
        # 开始计时并获取反应（带超时和退出检测）
        result = get_reaction_with_timeout(PORT, timeout=RESPONSE_TIMEOUT)
        
        # 检查退出
        if result and result.get('exit'):
            print("\n用户按白键退出实验")
            break
        
        # 检查超时
        if result is None:
            print(f"试次 {trial_num}: 反应超时")
            results.append({
                'trial': trial_num,
                'word': stim['word'],
                'color': stim['color'],
                'congruent': stim['congruent'],
                'correct_key': stim['correct_key'],
                'response_key': None,
                'response_name': 'timeout',
                't1_press': None,
                't2_release': None,
                'press_duration': None,
                'software_rt': None,
                'key_delay': None,
                'system_delay': None,
                'correct': False
            })
            
            # 超时反馈（黄色）
            feedback_stim.text = "反应超时，请集中注意！"
            feedback_stim.color = (1, 1, 0)
            feedback_stim.draw()
            win.flip()
            core.wait(1.0)
            continue
        
        # 判断正误及特殊情况
        expected_keys = set(KEY_MAPPING.values())
        is_correct = (result['key'] == stim['correct_key'])
        fast_response = result['t1'] < 200  # 反应过快阈值
        wrong_key = result['key'] not in expected_keys  # 按了非指定的按键
        
        # 保存数据
        trial_data = {
            'trial': trial_num,
            'word': stim['word'],
            'color': stim['color'],
            'congruent': stim['congruent'],
            'correct_key': stim['correct_key'],
            'response_key': result['key'],
            'response_name': decode_key_name(result['key']),
            't1_press': result['t1'],           # 按键按下反应时
            't2_release': result['t2'],         # 按键松开时间
            'press_duration': result['press_duration'],  # 按压持续时间
            'software_rt': result['software_rt'],        # 软件系统反应时
            'key_delay': result['press_duration'],       # 按键差值 = t2 - t1
            'system_delay': result['system_delay'],      # 系统差值
            'correct': is_correct
        }
        results.append(trial_data)
        
        # 显示反馈
        if fast_response:
            feedback_stim.text = f"反应过快（<200ms），请保持自然节奏\n反应时: {result['t1']} ms"
            feedback_stim.color = (0, 0.5, 1)  # 蓝色
        elif wrong_key:
            feedback_stim.text = "按错键，请使用指定按键"
            feedback_stim.color = (1, 1, 1)  # 白色
        elif is_correct:
            feedback_stim.text = f"反应正确\n按键反应时为 {result['t1']} ms\n松键反应时为 {result['t2']} ms"
            feedback_stim.color = (0, 1, 0)  # 绿色
        else:
            feedback_stim.text = "反应错误，请集中注意"
            feedback_stim.color = (1, 0, 0)  # 红色
        
        feedback_stim.draw()
        win.flip()
        core.wait(1.0)
        
        # 打印详细反馈
        print(f"\n试次 {trial_num}: {stim['word']}({stim['color']})")
        print(f"  结果: {'✓ 正确' if is_correct else '✗ 错误'}")
        print(f"  按键按下时间 (t1): {result['t1']} ms")
        print(f"  按键松开时间 (t2): {result['t2']} ms")
        print(f"  按压持续时间: {result['press_duration']} ms")
        print(f"  软件系统时间: {result['software_rt']:.2f} ms")
        print(f"  按键差值: {result['press_duration']} ms")
        print(f"  系统差值: {result['system_delay']:.2f} ms")
        
        # 试次间间隔
        win.flip()
        core.wait(1.0)
    
    return results


def show_results(results):
    """显示结果"""
    if not results:
        print("没有有效数据")
        return
    
    # 计算统计
    correct_trials = [r for r in results if r['correct']]
    accuracy = len(correct_trials) / len(results) * 100
    
    congruent_trials = [r for r in correct_trials if r['congruent']]
    incongruent_trials = [r for r in correct_trials if not r['congruent']]
    
    # 组装每一行文本，按相对高度逐行排布，避免不同分辨率重叠
    lines = [
        "实验完成！",
        f"总试次: {len(results)}",
        f"正确率: {accuracy:.1f}%",
    ]
    if congruent_trials:
        congruent_rt = sum(r['t1_press'] for r in congruent_trials) / len(congruent_trials)
        lines.append(f"一致试次平均RT: {congruent_rt:.0f} ms")
    if incongruent_trials:
        incongruent_rt = sum(r['t1_press'] for r in incongruent_trials) / len(incongruent_trials)
        lines.append(f"不一致试次平均RT: {incongruent_rt:.0f} ms")
    if congruent_trials and incongruent_trials:
        stroop_effect = incongruent_rt - congruent_rt
        lines.append(f"Stroop效应: {stroop_effect:.0f} ms")

    # 使用 height 单位的纵向栈布局
    line_height = 0.10  # 相对高度的行间距，适配中文字体行高
    start_y = 0.30      # 第一行 y 位置，居中稍上

    for i, text in enumerate(lines):
        line_stim = visual.TextStim(
            win,
            text=text,
            pos=(0, start_y - i * line_height),
            color='white',
            height=0.06,
            font=FONT,
            wrapWidth=1.4,
            alignText='center'
        )
        line_stim.draw()

    win.flip()
    core.wait(5)
    
    # 打印到控制台
    print("\n" + "=" * 60)
    print("\n".join(lines))
    print("=" * 60)


def cleanup():
    """清理资源"""
    try:
        if 'win' in globals() and win is not None:
            win.mouseVisible = True  # 恢复鼠标显示
            win.close()
    except Exception as e:
        print(f"关闭窗口时出错: {e}")
    
    try:
        core.quit()
    except (AttributeError, TypeError):
        # 忽略 logging stream 相关错误（常见于打包后的exe）
        pass


# ==================== 主程序 ====================

if __name__ == "__main__":
    try:
        # 获取实验配置
        EXP_INFO, TASK_TYPE, KEY_MAPPING = get_experiment_config()
        print(f"\n实验配置:")
        print(f"  被试: {EXP_INFO['name']}, {EXP_INFO['age']}岁, {EXP_INFO['gender']}")
        print(f"  任务类型: {'根据颜色按键' if TASK_TYPE == 'color' else '根据文字按键'}")
        print(f"  按键映射: 红→{decode_key_name(KEY_MAPPING['red'])}, 绿→{decode_key_name(KEY_MAPPING['green'])}\n")

        # 打开调试窗口，在窗口中后台连接反应盒
        print("正在打开调试窗口...")
        decision, PORT = run_pretest_window(port=None, device_id=None, connect_in_background=True)
        
        if decision == "exit" or decision is None:
            print("用户退出调试，程序结束")
            sys.exit(0)
        
        if PORT is None:
            raise RuntimeError("未能连接到反应盒！请检查连接/驱动")
        
        # 生成刺激列表
        if TASK_TYPE == 'color':
            STIMULI = [
                {'word': '红', 'color': 'red', 'congruent': True, 'correct_key': KEY_MAPPING['red']},
                {'word': '绿', 'color': 'green', 'congruent': True, 'correct_key': KEY_MAPPING['green']},
                {'word': '红', 'color': 'green', 'congruent': False, 'correct_key': KEY_MAPPING['green']},
                {'word': '绿', 'color': 'red', 'congruent': False, 'correct_key': KEY_MAPPING['red']},
            ]
        else:
            STIMULI = [
                {'word': '红', 'color': 'red', 'congruent': True, 'correct_key': KEY_MAPPING['red']},
                {'word': '绿', 'color': 'green', 'congruent': True, 'correct_key': KEY_MAPPING['green']},
                {'word': '红', 'color': 'green', 'congruent': False, 'correct_key': KEY_MAPPING['red']},
                {'word': '绿', 'color': 'red', 'congruent': False, 'correct_key': KEY_MAPPING['green']},
            ]
        
        setup(PORT)
        results = run_experiment()
        show_results(results)
        
        # 保存数据到当前工作目录下的相对路径
        if results:
            data_dir = Path("response_box_data")
            data_dir.mkdir(parents=True, exist_ok=True)
            
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            participant = safe_filename_fragment(EXP_INFO.get('name', 'unknown'))
            filename = data_dir / f'stroop_{participant}_{timestamp}.csv'
            
            # 添加被试信息到每一行
            df = pd.DataFrame(results)
            for key, value in EXP_INFO.items():
                df[key] = value
            df['task_type'] = TASK_TYPE
            df.to_csv(filename, index=False, encoding='utf-8-sig')
            
            print(f"\n数据已保存到: {filename}")
            print(f"共 {len(results)} 个试次")
        
    except KeyboardInterrupt:
        print("\n实验被用户中断")
    except Exception as e:
        print(f"\n实验出错: {e}")
        import traceback
        traceback.print_exc()
    finally:
        cleanup()
