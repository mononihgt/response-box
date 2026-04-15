# 初学者教程：从零开始搭建 response-box-eprime

这份教程面向**第一次做 E-Prime 实验**、或者**第一次把反应盒接入 E-Prime** 的同学。

目标不是教你“随便做一个 Stroop”，而是教你把本仓库里的 Python/PsychoPy 版行为，尽量原样搬到 `E-Prime 3.0`。

---

## 1. 你现在手上有什么

你现在已经有一套“半成品工程包”，放在：

- `response-box-eprime/README.md`
- `response-box-eprime/ebasic/`
- `response-box-eprime/lists/`
- `response-box-eprime/runtime/`
- `response-box-eprime/docs/`

它们的作用分别是：

- `ebasic/`：你要贴到 `E-Prime` 里的代码
- `lists/`：你要导入或照着填的表
- `runtime/`：真实反应盒找口脚本
- `docs/`：说明书和搭建教程

你可以把这套东西理解成：

- **不是一个已经编译好的 `.es3`**
- **而是一套可以被你亲手组装成 `.es3` 的“实验零件包”**

这是正常的，因为 `.es3` 是 `E-Prime` 的专有二进制工程格式，不能像 `.py`、`.ts` 那样直接在仓库里可靠生成。

---

## 2. 先理解：这个实验到底在做什么

如果你不先理解实验流程，后面在 `E-Studio` 里会很容易迷路。

这个实例程序的真实流程是：

1. 录入被试信息
2. 配置任务类型和红/绿键映射
3. 连接反应盒
4. 做一个实验前的“预检小窗”
5. 预检通过后进入正式实验
6. 每个 trial 都按固定时序运行
7. 被试通过反应盒按键作答
8. 程序显示反馈
9. 全部结束后显示统计结果
10. 保存结果数据

正式实验里每个 trial 的节奏是：

1. `@@` 掩蔽，`1000 ms`
2. `+` 注视点，`500 ms`
3. 呈现目标刺激
4. 反应盒开始计时并等待作答，最长 `2000 ms`
5. 显示反馈，`1000 ms`
6. 如果不是超时，再给一个空屏 `1000 ms`

这一套节奏就是你在 `E-Prime` 里要复刻的核心。

---

## 3. 先理解：反应盒在这里不是“键盘”

这是本项目最重要的一点。

本实例程序里：

- **正式输入设备是反应盒**
- **不是 PC 键盘**
- **不是让 E-Prime 自带 Keyboard 代替**

反应盒现在的接法是：

- 通过 USB 转串口
- 系统里表现为 `COM` 口
- 项目代码按串口协议直接和它通信

也就是说，你在 `E-Prime` 里做的事情不是：

- “监听空格键/左右键”

而是：

- 打开串口
- 发送命令给反应盒
- 读取反应盒返回的数据帧
- 自己解析 `key / t1 / t2`

这就是为什么本工程包里会有：

- `runtime/detect_reaction_box.ps1`
- `ebasic/UserScript_RB_Stroop.ebs`

---

## 4. 先理解：E-Prime 里几个最常见的对象

很多初学者卡住，不是代码不会写，而是连对象是什么都没分清。

### 4.1 `SessionProc`

你可以把它理解成：

- “整个实验的大流程”

谁先出现，谁后出现，都在这里排。

比如：

- 先配置
- 再预检
- 再指导语
- 再试次循环
- 再总结

这些都属于 `SessionProc`。

### 4.2 `TrialProc`

你可以把它理解成：

- “一个 trial 的内部流程”

例如：

- 先掩蔽
- 再 fixation
- 再刺激
- 再等待反应
- 再反馈

这些都属于 `TrialProc`。

### 4.3 `List`

你可以把它理解成：

- “给 Procedure 提供一行一行参数的表”

比如：

- `SessionList`：给整个实验提供被试配置
- `TrialList`：控制 trial 跑几次

### 4.4 `TextDisplay`

你可以把它理解成：

- “显示一段文字的屏幕对象”

比如：

- `@@`
- `+`
- 刺激文字
- 反馈文本

### 4.5 `Inline`

你可以把它理解成：

- “插一段 E-Basic 代码”

当界面对象本身做不了某个事时，就用 `Inline`。

例如：

- 初始化串口
- 等待反应盒返回数据
- 解析 8 字节数据帧
- 计算反馈内容
- 统计结果

这些都要用 `Inline`。

---

## 5. 先理解：这套工程为什么拆成这么多文件

初学者经常会问：

- 为什么不把所有代码都塞到一个地方？

因为那样在 `E-Prime` 里很难维护。

这里采用的是：

- **主函数放 `User Script`**
- **每个节点只放最小量的 `Inline`**

例如：

- `UserScript_RB_Stroop.ebs`：放公共函数
- `InLine_ConfigInline.ebs`：只做启动配置
- `InLine_PretestConnectInline.ebs`：只做反应盒连接
- `InLine_TrialResponseInline.ebs`：只做 trial 响应和反馈判定

这样你在 `E-Studio` 里调试时更容易定位问题。

---

## 6. 你开始前应该准备什么

在打开 `E-Studio` 前，先确认下面几件事。

### 6.1 软件

- 已安装 `E-Prime 3.0 (3.0.3.9)`
- 能打开 `E-Studio`

### 6.2 硬件

- 反应盒已接好
- CH341 驱动已安装
- Windows 设备管理器里能看到 `COM` 口

### 6.3 先跑一次找口脚本

在仓库根目录运行：

`powershell -ExecutionPolicy Bypass -File .\\response-box-eprime\\runtime\\detect_reaction_box.ps1 -AsJson`

如果一切正常，你会看到类似：

```json
{
  "port": "COM3",
  "device_id": "0001",
  "raw_length": 3
}
```

这说明：

- 反应盒真的连上了
- 串口真的能打开
- `0x5A 0x00` 握手真的成功了

这一步非常重要，因为它证明“硬件链路是通的”。

---

## 7. 最推荐的学习方式

不要一上来就想一次做完全部对象。

初学者最稳的顺序是：

1. 先建空工程
2. 先贴 `User Script`
3. 先把 `SessionProc` 建出来
4. 先做预检页面
5. 确认能连盒子
6. 再做 trial
7. 最后再调数据记录和总结页

也就是说，你应该把搭建过程拆成 3 个阶段：

### 阶段 A：能打开工程

目标：

- 工程结构完整
- 不报对象缺失

### 阶段 B：能连上反应盒

目标：

- `COM3` 打开成功
- 预检能读出按键

### 阶段 C：能跑完整实验

目标：

- trial 流程正确
- 数据字段正确
- 白键退出正常

---

## 8. 第一次搭建：最稳妥的操作顺序

这一节按“鼠标点哪里”的思路写。

### 第 1 步：新建实验

1. 打开 `E-Studio`
2. 新建实验
3. 把工程命名为 `RB_Stroop.es3`
4. 保存到你方便的位置

建议你先不要改太多默认设置，先能跑通。

### 第 2 步：粘贴 `User Script`

打开：

- `response-box-eprime/ebasic/UserScript_RB_Stroop.ebs`

把里面全部内容粘贴到实验级的 `User Script`。

这一步的意义是：

- 先把公共函数都放进去
- 后面的 `Inline` 才能调用这些函数

如果你跳过这一步，后面 `RB_Init`、`RB_WaitFrame` 一类函数都会报未定义。

### 第 3 步：配置 `StartupInfo`

按照 `response-box-eprime/docs/E_STUDIO_BUILD_STEPS.md` 中的字段逐个添加。

推荐你第一次先这样填：

- `participant_name = test`
- `participant_age = 18`
- `participant_gender = 男`
- `task_type = color`
- `red_key_code = 3`
- `green_key_code = 1`
- `rb_port = COM3`
- `rb_device_id = 0001`

第一次不要把变量留空，不然你会同时遇到“流程错误”和“界面错误”。

### 第 4 步：建 `SessionList`

先只做 1 行。

为什么？

因为这是初学者实例程序，不需要一开始做复杂的多被试批处理。

### 第 5 步：建 `SessionProc`

这一阶段不需要一次把所有对象细节都做完，先把这些名字建出来：

- `ConfigInline`
- `PretestConnectSlide`
- `PretestConnectInline`
- `PretestMenuSlide`
- `PretestLoopInline`
- `InstructionDisplay`
- `WaitStartInline`
- `TrialList`
- `SummaryInline`
- `SummaryDisplay`
- `SessionCleanupInline`

注意：

- 名字尽量和文档一致
- 初学者最常见错误就是对象名打错

### 第 6 步：先做预检，不急着做 trial

这是非常重要的教学建议。

你应该先做到：

- 打开工程
- 进入预检
- 真实按反应盒
- 屏幕上显示最近一次 `key/t1/t2/system_delay`

只要这一步通了，正式实验就成功了一半。

---

## 9. 预检阶段到底在做什么

预检阶段不是装饰页面，而是：

- 确认串口能打开
- 确认反应盒能握手
- 确认按键真的能回数据
- 确认 `t1/t2` 确实在回来

也就是说，预检是正式实验前的硬件验收。

### 预检阶段的 3 个关键对象

#### `PretestConnectInline`

负责：

- 读取 `rb_port`
- 初始化串口
- 发 `0x5A 0x00`
- 读取 `device_id`

#### `PretestMenuSlide`

负责：

- 告诉用户现在能做什么
- 显示 “按 1 开始/继续测试，按 2 进入实验，按 5 退出”

#### `PretestLoopInline`

负责：

- 真正读取反应盒数据
- 反复显示最新的键和值
- 白键结束测试

### 初学者常见误解

#### 误解 1：菜单页是键盘输入页

不是。

这里菜单显示在屏幕上，但正式输入来源仍然是：

- 反应盒串口

#### 误解 2：白键在预检里是退出整个实验

不是。

这里白键的作用是：

- 结束当前测试

然后你再决定：

- 继续测
- 进入实验
- 退出程序

---

## 10. 正式实验阶段到底在做什么

正式实验的重点是两个：

1. 保持 trial 时间结构和 Python 一致
2. 保持反应盒计时和数据字段一致

### 10.1 为什么 trial 不是直接在 List 里写 4 个刺激

因为 Python 版不是“4 个刺激平衡展开”。

它做的是：

- 每个 trial 都从 4 个模板里**随机抽一个**
- 一共抽 `12` 次
- 是**有放回抽样**

这意味着：

- 某个刺激可能重复很多次
- 某个刺激可能这次一个都没抽中

这听起来不“平衡”，但这是当前 Python 版的真实行为。

本实例程序要教你的不是“设计更好”，而是“复刻真实行为”。

所以：

- `TrialList` 只放 `trial_index`
- 真正的刺激选择在 `TrialStimulusPrepInline` 完成

### 10.2 为什么 `StimulusDisplay` 后面紧跟 `TrialResponseInline`

因为当前 Python 逻辑是：

1. 屏幕 flip 显示刺激
2. 紧接着调用 `get_reaction_time()`
3. 在函数内部发送 `FC 00` 和 `FB 00`

所以在 `E-Prime` 里最接近的做法是：

- 先显示刺激
- 然后马上执行读串口逻辑

这就是为什么响应逻辑放在紧跟刺激后的 `Inline`，而不是交给普通 Keyboard/InputMask。

---

## 11. 反应盒数据到底怎么来的

这一节你必须搞懂。

### 11.1 查询设备号

发送：

- `0x5A 0x00`

如果设备回应正常，你会收到：

- `0x5A + 设备号`

### 11.2 开始计时

每个 trial 在等待响应前，会发送：

1. `0xFC 0x00`
2. 等 `10 ms`
3. `0xFB 0x00`

含义是：

- 先停止旧计时
- 再开始新计时

### 11.3 读取返回帧

程序等待 8 字节：

- `[FB][key][t1_hi][t1_lo][t2_hi][t2_lo][ide_hi][ide_lo]`

然后自己解析出：

- `key`
- `t1`
- `t2`
- `press_duration`
- `software_rt`
- `system_delay`

### 11.4 为什么 `t1` 最重要

因为：

- `t1` 是按下时刻
- 这是心理学里最标准的 RT 定义
- 它来自硬件计时
- 不依赖 PC 键盘时间

---

## 12. 初学者最容易出错的地方

### 12.1 对象名写错

比如文档里是：

- `TrialResponseInline`

你在工程里写成：

- `Trial_Response_Inline`

结果就是：

- 文档和工程对不上
- 调试时很痛苦

建议：

- 严格照 `OBJECT_MAP.md` 命名

### 12.2 还没贴 `User Script` 就先跑 `Inline`

结果：

- `RB_Init` 未定义
- `RB_WaitFrame` 未定义

### 12.3 用 Keyboard 先凑合

本项目不建议这么做。

如果你真要临时定位界面问题，可以短暂用键盘验证页面跳转，
但你必须明确写：

- **仅用于调试，不是最终方案**

正式实现一定要回到：

- 真实反应盒串口输入

### 12.4 把 4 个刺激模板直接做成 12 行固定表

这样会改变原程序行为。

### 12.5 忘了超时 trial 不记入结果

Python 版的逻辑是：

- 超时只给反馈
- 不写 trial 数据

如果你在 `E-Prime` 里把超时也写入正式 trial 结果，正确率和汇总都会变掉。

---

## 13. 第一次测试时你应该怎么做

第一次联调不要直接做完整 12 trial。

建议按下面顺序测。

### 测试 1：只测找口脚本

运行：

`response-box-eprime/runtime/detect_reaction_box.ps1`

确认：

- 能找到 `COM3`
- 能读到 `0001`

### 测试 2：只测预检连接

确认：

- 工程能打开
- `PretestConnectInline` 不报错
- `rb_device_id` 能显示

### 测试 3：只测预检按键

确认：

- 反应盒任意彩键能被显示
- `t1/t2/system_delay` 会更新
- 白键能结束测试

### 测试 4：只测开始页

确认：

- 指导语页显示正确
- 任意反应盒键能开始

### 测试 5：只测 1 个 trial

确认：

- mask → fixation → stimulus → response → feedback → iti

### 测试 6：测完整 12 trial

确认：

- 数据保存正确
- 总结页正确

---

## 14. 如果运行失败，先看哪一层

遇到问题不要慌，按层排查。

### 层 1：硬件层

看：

- 反应盒是否通电
- USB 线是否正常
- 驱动是否正常
- Windows 是否能看到 `COM` 口

### 层 2：串口层

看：

- `detect_reaction_box.ps1` 是否成功
- `rb_port` 是否填对
- 有没有别的程序占用同一 `COM`

### 层 3：E-Prime 代码层

看：

- `User Script` 是否已粘贴
- `Inline` 是否贴到正确对象
- 对象名是否一致

### 层 4：实验逻辑层

看：

- trial 时序是否正确
- `correct_key` 是否按任务类型计算
- 超时 / 白键 / 过快逻辑是否正确

---

## 15. 初学者应该先学会看哪些文件

如果你想真正理解这个实例程序，我建议按这个顺序看：

### 第一层：先看总说明

- `response-box-eprime/README.md`

### 第二层：看对象结构

- `response-box-eprime/docs/OBJECT_MAP.md`

### 第三层：看搭建步骤

- `response-box-eprime/docs/E_STUDIO_BUILD_STEPS.md`

### 第四层：看核心脚本

- `response-box-eprime/ebasic/UserScript_RB_Stroop.ebs`

重点看这几个函数：

- `RB_Init`
- `RB_QueryDeviceId`
- `RB_WaitFrame`
- `RB_SummaryText`

### 第五层：看每个 `Inline`

建议从这几个开始：

- `InLine_ConfigInline.ebs`
- `InLine_PretestConnectInline.ebs`
- `InLine_TrialStimulusPrepInline.ebs`
- `InLine_TrialResponseInline.ebs`

---

## 16. 你现在真正要做的，不是“背代码”

初学者最容易把重点放错。

你现在最重要的学习目标不是：

- 把所有 E-Basic 语法都背下来

而是：

1. 理解实验流程
2. 理解对象之间谁调用谁
3. 理解反应盒数据从哪来
4. 理解每个 `Inline` 为什么放在这里

只要这四件事清楚了，后面改任务、改刺激、改反馈，你都会更稳。

---

## 17. 给初学者的最终建议

### 建议 1

第一次不要追求“又漂亮又完整”，先追求：

- 真机能跑通

### 建议 2

每做完一小步就保存一次。

### 建议 3

一旦能读到 `t1/t2`，先庆祝一下，因为最难的硬件环节已经过了。

### 建议 4

不要轻易把正式实现改成键盘版。

这是一个“反应盒正式接入”的教学实例，最有价值的部分恰恰是：

- 串口通信
- 硬件计时
- 自己解析返回帧

---

## 18. 下一步你可以怎么继续学

如果你已经完成第一次搭建，下一步可以继续练习：

1. 把 `task_type` 改成 `word`，观察正确键如何变化
2. 改一改红/绿映射，确认逻辑仍正确
3. 故意按未映射按键，观察 `wrong key` 反馈
4. 故意超时，观察是否真的不记 trial
5. 故意按白键，观察是否在 trial 内退出

这些练习能帮助你真正吃透整个实例程序。

---

## 19. 配套阅读

- 对象结构：`response-box-eprime/docs/OBJECT_MAP.md`
- 手工搭建：`response-box-eprime/docs/E_STUDIO_BUILD_STEPS.md`
- 数据字段：`response-box-eprime/docs/DATA_MAPPING.md`
- 验收清单：`response-box-eprime/docs/VALIDATION_CHECKLIST.md`
- 核心代码：`response-box-eprime/ebasic/UserScript_RB_Stroop.ebs`

如果你愿意，下一步我还可以继续补两份更适合初学者的材料：

1. **“对象属性表”**：每个对象在 `E-Studio` 里每一项怎么填  
2. **“报错排查手册”**：按实际报错一句一句教你修
