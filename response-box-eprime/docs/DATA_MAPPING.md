# 数据字段映射

## 与 Python CSV 对齐字段

| 字段名 | 级别 | 说明 |
|---|---|---|
| `trial` | trial | 试次编号 |
| `word` | trial | 刺激文字 |
| `color` | trial | 刺激颜色 |
| `congruent` | trial | 一致/不一致 |
| `correct_key` | trial | 正确反应键号 |
| `response_key` | trial | 实际反应键号 |
| `response_name` | trial | 实际反应键名 |
| `t1_press` | trial | 按下时刻 RT |
| `t2_release` | trial | 松开时刻 RT |
| `press_duration` | trial | 按压持续时间 |
| `software_rt` | trial | 软件计时总时长 |
| `key_delay` | trial | 与 Python 同义，等于 `press_duration` |
| `system_delay` | trial | 软件减去 `t2` 的差值 |
| `correct` | trial | 是否正确 |
| `name` | participant | 被试姓名 |
| `age` | participant | 被试年龄 |
| `gender` | participant | 被试性别 |
| `date` | participant | 运行日期 |
| `time` | participant | 运行时间 |
| `task_type` | participant | `color` 或 `word` |

## 不写入正式 CSV 的硬件字段

- `ide`

## 统计口径

- `total trials` = 已记录 trial 数，不含超时、不含白键退出
- `accuracy` = `correct / logged_trials`
- `congruent mean RT` = 正确且一致 trial 的 `t1_press` 均值
- `incongruent mean RT` = 正确且不一致 trial 的 `t1_press` 均值
- `stroop effect` = `incongruent mean RT - congruent mean RT`
