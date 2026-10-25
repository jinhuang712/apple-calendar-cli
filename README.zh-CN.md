<div align="center">

<img src="assets/hero.svg" alt="acal：在命令行里读写 Mac 的日历" width="100%">

<br>

[![test](https://github.com/jinhuang712/apple-calendar-cli/actions/workflows/test.yml/badge.svg)](https://github.com/jinhuang712/apple-calendar-cli/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-2563eb?style=flat-square)](LICENSE)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-111827?style=flat-square&logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-F05138?style=flat-square&logo=swift&logoColor=white)
![Output: JSON](https://img.shields.io/badge/output-JSON-10b981?style=flat-square)
![Built for AI agents](https://img.shields.io/badge/built%20for-AI%20agents-a855f7?style=flat-square)

[English](README.md) · **简体中文**

</div>

## ✨ 它是什么

`acal` 读写 macOS 日历（Calendar）里的日程。它面向系统的日历数据库，而不是某一家服务，所以日历 App 里有的账户（iCloud、Google、Exchange 等）都能用。

- 🔌 **为管道而生。** 列表一行一个 JSON 对象。结果写到 stdout，提示写到 stderr，退出码说明结果。
- 🛡️ **没人看着时也安全。** 删除、修改重复日程，默认只预览，加 `--yes` 才执行。重复日程必须写明 `--span`。
- 🎯 **一个命令只做一件事。** 没有搜索、没有查空档、没有配置文件，过滤交给 `jq`。
- 🔁 **重复日程处理得当。** 可以只改某一次，或改这一次和之后的所有次。
- 📡 **也管订阅日历。** 添加、删除、刷新。
- 🤖 **自带 skill，** 教 Claude Code 怎么用它而不弄坏你的日历。

> [!TIP]
> 凡是会删除、或会改动重复日程的命令，都先打印预览然后停下。看清楚了，再加 `--yes` 重新运行同一条命令。

## 👀 一眼看懂

下面的数据是编的，输出的格式是真的。

```console
$ acal events --from 2026-11-03 --to 2026-11-04 | jq -c '{title, start, calendar}'
{"title":"Team sync","start":"2026-11-03T10:00:00Z","calendar":"Work"}
{"title":"Dentist","start":"2026-11-03T15:00:00Z","calendar":"Personal"}

$ acal add --title "Gym" --start 2026-11-05T07:00:00Z --end 2026-11-05T08:00:00Z \
    --repeat weekly --count 4 --alarm 15m
{"allDay":false,"calendar":"Personal","id":"…","recurrenceRule":{"count":4,"frequency":"weekly","interval":1},…}

$ acal rm <id> --span future --occurrence 2026-11-12T07:00:00Z      # 只是预览，不会删
{"events":[{"start":"2026-11-12T07:00:00Z","title":"Gym",…},{"start":"2026-11-19T07:00:00Z","title":"Gym",…}],"preview":true}

$ acal rm <id> --span future --occurrence 2026-11-12T07:00:00Z --yes
{"events":[…],"removed":true}
```

## ⌨️ 命令

| 想做的事 | 命令 |
|---|---|
| 查看或请求日历授权 | `acal auth [--request]` |
| 列出所有日历 | `acal calendars` |
| 列出一段时间内的日程 | `acal events --from <时间> --to <时间> [--calendar <名称或 id>]` |
| 看一个日程的全部字段 | `acal event <id> [--occurrence <时间>]` |
| 新建日程 | `acal add --title … --start … --end … [--all-day] [--alarm 30m] [--repeat weekly --count 4]` |
| 修改日程 | `acal edit <id> [字段] [--occurrence <时间>] [--span this\|future] [--yes]` |
| 删除日程 | `acal rm <id> [--occurrence <时间>] [--span this\|future] [--yes]` |
| 添加订阅日历 | `acal subscribe <webcal:// 或 https:// 地址>` |
| 删除订阅日历 | `acal unsubscribe <日历 id> [--yes]` |
| 重新加载所有日历 | `acal refresh` |

时间用 ISO 8601。不带时区偏移的时间按系统时区解释；只写日期表示那一天的开始（`--to` 则是那一天的结束）。每个命令都有 `--help`。

每个命令做什么、出错时输出什么、刻意不做什么，见 [FEATURES.md](FEATURES.md)。

## 📦 安装

需要 macOS 14 或更高，以及 Swift 工具链（Xcode 或命令行工具）。

```bash
git clone https://github.com/jinhuang712/apple-calendar-cli.git
cd apple-calendar-cli
swift build -c release
ln -s "$PWD/.build/release/acal" ~/.local/bin/acal    # 或放到 PATH 里任意位置
```

然后给终端开通日历权限：运行 `acal auth --request` 并点**允许**，或到**系统设置 → 隐私与安全性 → 日历**里打开（选"完全访问"）。用 `acal auth` 检查。

zsh、bash、fish 的补全脚本：`acal --generate-completion-script zsh`。

### 🤖 给 Claude Code 装 skill

skill 教 agent 怎么安全地用 `acal`：先预览再 `--yes`、重复日程要写范围、哪些步骤要人点一下。一行命令：

```bash
curl -fsSL https://raw.githubusercontent.com/jinhuang712/apple-calendar-cli/master/install.sh | sh
```

它把 [`skills/apple-calendar/SKILL.md`](skills/apple-calendar/SKILL.md) 装到 `~/.claude/skills/apple-calendar/`，重复运行会覆盖。它只装 skill，不装 `acal` 本身。

## 💡 需要知道的

> [!IMPORTANT]
> **授权属于你的终端，不属于 `acal`。** 换一个终端 App，要给新的终端也授权。

- **订阅通过日历 App 完成。** `subscribe`、`unsubscribe`、`refresh` 驱动日历 App 自己的脚本接口，因为系统的日历框架管不了订阅。终端还要获得"控制日历"的授权（**隐私与安全性 → 自动化**）。
- **`subscribe` 需要人。** 日历 App 会弹出两个窗口，要有人逐个确认。命令打开窗口后立即返回。
- **`refresh` 会重新加载所有日历，** 也无法告诉你新内容有没有到。
- **做不到的事：** 添加或回复受邀人、写入订阅日历或生日日历、附件。
- 在 Apple 芯片的 macOS 27 上测试过。其他版本和 Intel Mac 没有测。

## 📚 文档

| | |
|---|---|
| [FEATURES.md](FEATURES.md) | 每个命令做什么、刻意不做什么 |
| [DESIGNS.md](DESIGNS.md) | 设计原则，以及反直觉的选择为什么这样选 |
| [CHANGELOG.md](CHANGELOG.md) | 每个版本的变化（英文） |
| [CONTRIBUTING.md](CONTRIBUTING.md) | 怎么构建、测试、提交修改（英文） |
| [SECURITY.md](SECURITY.md) | 怎么报告安全问题（英文） |

## 📄 许可证

[MIT](LICENSE)
