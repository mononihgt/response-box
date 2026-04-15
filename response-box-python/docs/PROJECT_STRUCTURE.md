# 反应盒项目结构说明

## 📁 项目结构

```
response_box_windows/
├── src/                          # 核心工具库
│   ├── __init__.py              # 模块初始化
│   ├── serial_utils.py          # 串口查找和连接工具
│   ├── reaction_box.py          # 反应盒核心功能
│   └── test_utils.py            # 测试工具函数
│
├── main.py                       # 命令行调试主程序
├── experiment_psychopy.py        # PsychoPy实验示例
├── demo.py                       # 旧版演示程序（保留作参考）
│
├── 反应盒使用教程.md
├── 反应时参数与误差分析.md
├── 反应盒学习指南.md
├── 反应盒参数说明.md
└── README.md
```

## 🚀 使用方法

### 1. 命令行调试模式

运行测试和调试：
```bash
uv run main.py
```

或：
```bash
python main.py
```

提供以下测试选项：
- 基础连接测试
- 按键检测测试
- 反应时测量测试
- 系统延迟校准
- 详细参数测试
- 简单实验演示

### 2. PsychoPy实验模式

运行Stroop任务示例：
```bash
uv run experiment_psychopy.py
```

或：
```bash
python experiment_psychopy.py
```

### 3. 自定义实验

创建你自己的实验文件，导入需要的工具：

```python
from src import auto_find_reaction_box, get_reaction_time, decode_key_name

# 1. 查找反应盒
PORT = auto_find_reaction_box()

# 2. 在实验中使用
result = get_reaction_time(PORT)

# 3. 获取数据
rt = result['t1']  # 反应时
key = result['key']  # 按键编号
```

## 📦 核心模块说明

### src/serial_utils.py
串口工具函数：
- `list_all_ports()` - 列出所有串口
- `check_port(port)` - 检查串口是否可用
- `check_reaction_box(port)` - 检查是否为反应盒
- `auto_find_reaction_box()` - 自动查找反应盒

### src/reaction_box.py
反应盒核心功能：
- `get_reaction_time(port, ...)` - 获取反应时数据（返回完整字典）
- `decode_key_name(key_num)` - 按键编号转名称

### src/test_utils.py
测试工具函数：
- `test_basic_connection(port)` - 连接测试
- `test_key_detection(port)` - 按键测试
- `test_reaction_time(port)` - 反应时测试
- `calibrate_system_delay(port)` - 系统延迟校准
- `test_detailed_parameters(port)` - 详细参数测试
- `demo_simple_experiment(port)` - 简单实验演示

## 💡 开发新实验

### 最简示例

```python
from src import auto_find_reaction_box, get_reaction_time

# 初始化
PORT = auto_find_reaction_box()

# 实验循环
for trial in range(10):
    print(f"\n刺激 {trial + 1}")
    
    # 呈现刺激（你的代码）
    # ...
    
    # 获取反应
    result = get_reaction_time(PORT)
    
    # 使用数据
    print(f"反应时: {result['t1']} ms")
    print(f"按键: {result['key']}")
```

### PsychoPy集成

```python
from psychopy import visual, core
from src import auto_find_reaction_box, get_reaction_time

# 初始化
PORT = auto_find_reaction_box()
win = visual.Window(size=(800, 600))
text = visual.TextStim(win, text='刺激')

# 实验循环
for trial in range(10):
    # 呈现刺激
    text.draw()
    win.flip()
    
    # 获取反应（计时自动开始）
    result = get_reaction_time(PORT, show_prompt=False)
    
    # 记录数据
    data = {
        'trial': trial,
        'rt': result['t1'],
        'key': result['key']
    }
```

## 📊 返回数据格式

`get_reaction_time()` 返回字典包含：

```python
{
    'key': 1,                    # 按键编号 (1-5)
    't1': 387,                   # 按键按下时间 (ms) - 主要反应时
    't2': 542,                   # 按键松开时间 (ms)
    'press_duration': 155,       # 按压持续时间 (ms)
    'software_rt': 558.23,       # 软件测量时间 (ms)
    'system_delay': 16.23,       # 系统误差 (ms)
    'ide': 1                     # 校验值
}
```

**重要：实验中应使用 `t1` 作为反应时！**

## 🔑 按键对应

| 编号 | 颜色 | 说明 |
|------|------|------|
| 1 | 绿色 | 通常表示"是"、"正确" |
| 2 | 蓝色 | 备用 |
| 3 | 红色 | 通常表示"否"、"错误" |
| 4 | 黄色 | 备用 |
| 5 | 白色 | 退出键 |

## 📝 注意事项

1. **计时顺序**：呈现刺激 → 调用`get_reaction_time()` → 等待按键
2. **使用t1**：在实验中应使用`t1`作为反应时测量值
3. **系统延迟**：运行"系统延迟校准"了解你的系统延迟（通常10-30ms）
4. **数据保存**：建议保存完整的字典数据，便于后续分析

## 🆘 常见问题

**Q: 找不到反应盒？**
A: 检查USB连接、驱动安装、设备通电

**Q: 反应时异常？**
A: 运行"详细参数测试"查看各项时间参数

**Q: 如何校准系统延迟？**
A: 运行main.py，选择"4. 系统延迟校准"

---

**更新日期**: 2025-12-19
**版本**: 2.0（模块化重构版）
