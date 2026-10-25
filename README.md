# apple-calendar-cli

`acal` 是读写 Mac 日历（Calendar）日程的命令行工具。每个命令只做一件事，输出是 JSON，方便脚本和 agent 调用。

## 现在能做什么

还没有功能。项目刚建好骨架，下面是计划，每个功能的状态见 [FEATURES.md](FEATURES.md)：

- 授权、列出日历
- 按时间范围列日程、取单个日程
- 新建、修改、删除日程，支持重复规则和提醒
- 添加、删除、刷新订阅日历

## 安装

尚未验证。计划用 Swift Package Manager 从源码构建：

```bash
swift build -c release
```

## 已知限制

- 只支持 macOS，最低 14。
- 日历授权记在运行 `acal` 的终端头上，换终端要重新授权，见 [FEATURES.md](FEATURES.md) 的 F1。
- 添加订阅需要人在日历 App 里确认两次，无法无人值守。

## 文档

| 文档 | 内容 |
|---|---|
| [FEATURES.md](FEATURES.md) | 每个功能的行为、状态、出错情况，以及不做什么 |
| [CHANGELOG.md](CHANGELOG.md) | 版本变化 |
