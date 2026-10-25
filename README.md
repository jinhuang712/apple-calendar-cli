# apple-calendar-cli

`acal` 是读写 Mac 日历（Calendar）日程的命令行工具。每个命令只做一件事，输出是 JSON，方便脚本和 agent 调用。

## 能做什么

| 想做的事 | 命令 |
|---|---|
| 查看或请求日历授权 | `acal auth [--request]` |
| 列出所有日历 | `acal calendars` |
| 列出一段时间内的日程 | `acal events --from 2026-11-01 --to 2026-11-08` |
| 看一个日程的全部字段 | `acal event <id>` |
| 新建日程，可带重复规则和提醒 | `acal add --title "牙医" --start 2026-11-03T15:00:00 --end 2026-11-03T16:00:00` |
| 修改日程 | `acal edit <id> --title "新标题"` |
| 删除日程 | `acal rm <id> --yes` |
| 添加、删除、刷新订阅日历 | `acal subscribe <地址>`、`acal unsubscribe <id> --yes`、`acal refresh` |

删除，以及对重复日程的修改，默认只预览，加 `--yes` 才真正执行。每个功能的行为、状态和出错情况见 [FEATURES.md](FEATURES.md)。

## 安装

用 Swift Package Manager 从源码构建，需要 macOS 14 或更高：

```bash
swift build -c release
.build/release/acal auth
```

### 给 Claude Code 装 skill

skill 教 agent 怎么安全地使用 `acal`：先预览再执行、重复日程要写范围、订阅要人确认。一行命令安装：

```bash
curl -fsSL https://raw.githubusercontent.com/jinhuang712/apple-calendar-cli/master/install.sh | sh
```

它把 [skills/apple-calendar/SKILL.md](skills/apple-calendar/SKILL.md) 装到 `~/.claude/skills/apple-calendar/`，重复运行会覆盖。它只装 skill，不装 `acal` 本身，所以仍要先按上面的步骤构建。上面这个地址要等仓库公开后才可用，目前只用本地文件服务器测过脚本。

### 第一次使用前

要在系统设置 > 隐私与安全性 > 日历里，给你运行 `acal` 的终端打开"完全访问"。

## 已知限制

- 日历授权记在运行 `acal` 的终端头上，换终端要重新授权。
- 订阅的添加、删除、刷新通过日历 App 完成，终端还要获得"控制日历"的授权。
- 添加订阅需要人在日历 App 里确认两次，无法无人值守。
- 刷新订阅只能刷新全部日历，也无法确认内容真的更新了。
- 不能添加或回复受邀人、不能写入附件。完整的不做清单见 [FEATURES.md](FEATURES.md)。

## 文档

| 文档 | 内容 |
|---|---|
| [FEATURES.md](FEATURES.md) | 每个功能的行为、状态、出错情况，以及不做什么 |
| [DESIGNS.md](DESIGNS.md) | 设计原则，以及反直觉的选择为什么这样选 |
| [CHANGELOG.md](CHANGELOG.md) | 版本变化 |
