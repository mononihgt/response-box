# E-Studio 手工搭建步骤

## 1. 新建工程

1. 打开 `E-Studio`
2. 新建实验 `RB_Stroop.es3`
3. 目标版本使用本机 `E-Prime 3.0 (3.0.3.9)`
4. 在 `Experiment` 级粘贴 `ebasic/UserScript_RB_Stroop.ebs`

## 2. 配置 StartupInfo

在 `StartupInfo` 中新增以下字段：

- `participant_name`
- `participant_age`
- `participant_gender`
- `task_type`
- `red_key_code`
- `green_key_code`
- `rb_port`
- `rb_device_id`

推荐默认值：

- `participant_name = `
- `participant_age = `
- `participant_gender = 男`
- `task_type = color`
- `red_key_code = 3`
- `green_key_code = 1`
- `rb_port = COM3`
- `rb_device_id = 0001`

## 3. 建立 SessionList

1. 插入 `List`，命名 `SessionList`
2. 过程绑定到 `SessionProc`
3. 列名按 `lists/SessionList.csv`
4. 建议先只放 1 行

## 4. 建立 SessionProc

按 `docs/OBJECT_MAP.md` 顺序建立对象。

### 4.1 `ConfigInline`

- 类型：`Inline`
- 粘贴：`ebasic/InLine_ConfigInline.ebs`

### 4.2 `PretestConnectSlide`

- 类型：`TextDisplay`
- 背景：浅蓝灰
- 文本绑定：
  - `当前反应盒端口号：[rb_port]`
  - `当前反应盒序列号：[rb_device_id]`
  - `[pretest_status]`
- `Duration = 0`

### 4.3 `PretestConnectInline`

- 类型：`Inline`
- 粘贴：`ebasic/InLine_PretestConnectInline.ebs`

### 4.4 `PretestMenuSlide`

- 类型：`TextDisplay`
- 文本内容：
  - `当前反应盒端口号：[rb_port]`
  - `当前反应盒序列号：[rb_device_id]`
  - `[pretest_status]`
  - `按 1 开始/继续测试`
  - `按 2 进入实验`
  - `按 5 退出`
- `Duration = 0`
- 该页只是菜单提示，正式输入仍由 `PretestLoopInline` 读取反应盒

### 4.5 `PretestLoopInline`

- 类型：`Inline`
- 粘贴：`ebasic/InLine_PretestLoopInline.ebs`

### 4.6 `InstructionDisplay`

- 类型：`TextDisplay`
- `Duration = 0`
- 文本：
  - `Stroop任务`
  - `[task_desc]`
  - `红 → [red_key_name]`
  - `绿 → [green_key_name]`
  - `随时可按白键退出`
  - `请又快又准地反应`
  - `按任意反应盒键开始`

### 4.7 `WaitStartInline`

- 类型：`Inline`
- 粘贴：`ebasic/InLine_WaitStartInline.ebs`

### 4.8 `TrialList`

1. 插入 `List`，命名 `TrialList`
2. 过程绑定到 `TrialProc`
3. 内容使用 `lists/TrialList.csv`

### 4.9 `SummaryInline`

- 类型：`Inline`
- 粘贴：`ebasic/InLine_SummaryInline.ebs`

### 4.10 `SummaryDisplay`

- 类型：`TextDisplay`
- `Duration = 5000`
- 文本绑定：`[summary_text]`

### 4.11 `SessionCleanupInline`

- 类型：`Inline`
- 粘贴：`ebasic/InLine_SessionCleanupInline.ebs`

## 5. 建立 TrialProc

### 5.1 `TrialStimulusPrepInline`

- 类型：`Inline`
- 粘贴：`ebasic/InLine_TrialStimulusPrepInline.ebs`

### 5.2 `MaskDisplay`

- 类型：`TextDisplay`
- 文本：`@@`
- 颜色：白色
- 背景：黑色
- `Duration = 1000`

### 5.3 `FixationDisplay`

- 类型：`TextDisplay`
- 文本：`+`
- 颜色：白色
- 背景：黑色
- `Duration = 500`

### 5.4 `StimulusDisplay`

- 类型：`TextDisplay`
- 文本绑定：`[word]`
- 颜色绑定：`[color]`
- 背景：黑色
- `Duration = 0`

### 5.5 `TrialResponseInline`

- 类型：`Inline`
- 粘贴：`ebasic/InLine_TrialResponseInline.ebs`

### 5.6 `FeedbackDisplay`

- 类型：`TextDisplay`
- 文本绑定：`[feedback_text]`
- 颜色绑定：`[feedback_color]`
- 背景：黑色
- `Duration = 1000`

### 5.7 `ITIInline`

- 类型：`Inline`
- 粘贴：`ebasic/InLine_ITIInline.ebs`

### 5.8 `ITIDisplay`

- 类型：`TextDisplay`
- 空文本
- 黑底
- `Duration = 1000`
- 只在 `trial_logged = 1` 时保留；超时 trial 通过 `ITIInline` 把时长设为 0

## 6. 串口检测

正式推荐先运行：

`powershell -ExecutionPolicy Bypass -File .\\runtime\\detect_reaction_box.ps1`

把输出的 `COM` 号填回 `StartupInfo.rb_port`。

如果实验室环境端口稳定，也可直接固定 `COMx`。

## 7. 列表模板

- `lists/SessionList.csv`
- `lists/TrialList.csv`
- `lists/StimulusTemplates_color.csv`
- `lists/StimulusTemplates_word.csv`

刺激模板文件主要用于核对逻辑，不建议直接把它们作为主试次表，否则会改变 Python 的“有放回随机抽样”行为。
