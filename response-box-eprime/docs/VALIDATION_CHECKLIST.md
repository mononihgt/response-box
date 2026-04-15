# 验收清单

## 真机接入

- [ ] `detect_reaction_box.ps1` 能找到正确 `COM` 口
- [ ] `0x5A 0x00` 查询能返回 `device_id`
- [ ] `E-Prime` 能成功 `Open` 串口
- [ ] trial 开始前能发送 `0xFC 0x00`
- [ ] 刺激呈现后能发送 `0xFB 0x00`
- [ ] 能收到完整 8 字节数据帧
- [ ] `t1/t2` 为硬件返回，不是键盘时间

## 行为一致性

- [ ] `12` 次 trial
- [ ] trial 为 4 模板有放回随机抽样
- [ ] `@@ 1000ms`
- [ ] `+ 500ms`
- [ ] 反应等待 `2000ms`
- [ ] 反馈 `1000ms`
- [ ] 非超时 trial 额外 `1000ms ITI`
- [ ] 白键 trial 内退出
- [ ] 开始页为任意反应盒键启动

## 判定一致性

- [ ] `fast_response < 200ms`
- [ ] 过快优先级高于 wrong key
- [ ] wrong key 仅指未映射的另外两枚彩键
- [ ] 正确反馈显示 `t1/t2`
- [ ] 超时不写 trial 数据

## 数据一致性

- [ ] 导出列名与 `docs/DATA_MAPPING.md` 一致
- [ ] `accuracy` 分母不含超时
- [ ] 统计只用正确 trial 算条件均值
