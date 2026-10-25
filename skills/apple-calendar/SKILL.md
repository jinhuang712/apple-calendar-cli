---
name: apple-calendar
description: Read and change the user's macOS Calendar with the `acal` command: list calendars, list or show events, add, edit and delete events (including repeating ones), and manage subscribed calendars. Use when the user asks about their schedule, wants an event created, moved or removed, or wants a calendar subscription added, removed or refreshed.
---

# Apple Calendar with `acal`

`acal` reads and writes the Mac's Calendar. Every command prints JSON on stdout (lists are one object per line), prints hints on stderr, and uses an exit code. Filter with `jq`; the commands do not search.

Run `command -v acal` first. When it is missing, tell the user to install it from the project README and stop. Do not build it yourself.

## Before anything else: authorization

Run `acal auth`. It prints `{"status": ...}`.

| status | what to do |
|---|---|
| `granted` | go on |
| `notDetermined` | run `acal auth --request`; the user must click the system prompt |
| `denied`, `writeOnly` | tell the user to give their terminal Full Access in System Settings > Privacy & Security > Calendars. Do not retry; no prompt will appear |
| `restricted` | a profile on the Mac forbids it; tell the user |

Exit code 3 from any command means "not authorized". Fix the authorization; retrying does not help.

## Read

```bash
acal calendars                                            # id, title, account, type, readOnly
acal events --from 2026-11-01 --to 2026-11-08 [--calendar <name or id>]
acal event <id> [--occurrence <start time>]               # notes, url, alarms, recurrenceRule, attendees
```

- Times are ISO 8601 (`2026-11-03T15:00:00+08:00`). Without an offset they are read in the system time zone. A bare date in `--to` means the end of that day.
- The range is at most one year.
- Every occurrence of a repeating event has the same `id`. Tell them apart by `start`, and pass it as `--occurrence`.
- An alarm like `30m` is before the start. A negative one, like `-9h`, is after it.

## Write

```bash
acal add --title "Dentist" --start 2026-11-03T15:00:00 --end 2026-11-03T16:00:00 \
  [--calendar <name or id>] [--location ..] [--notes ..] [--url ..] \
  [--alarm 30m]... [--repeat daily|weekly|monthly|yearly --interval N --count N | --until <date>]
acal add --title "Holiday" --start 2026-12-24 --all-day            # --end defaults to --start
acal edit <id> [fields as in add] [--occurrence <time>] [--span this|future] [--yes]
acal rm <id> [--occurrence <time>] [--span this|future] [--yes]
```

- `--alarm` or `--repeat` on `edit` replaces what the event had. There is no way to only clear one.
- Without `--calendar`, the event goes to the user's default calendar. Read-only calendars (subscriptions, birthdays, some holiday calendars) cannot be changed.

## Destructive commands preview first

`rm`, `edit` on a repeating event, and `unsubscribe` only show a preview (`"preview": true`) until `--yes` is given.

1. Run the command without `--yes`.
2. Show the user what it lists. Run it again with `--yes` only after the user agrees.

For a repeating event, `--span` is required and has no default. `--span this` also needs `--occurrence`. After `edit --span future`, the later part is a new series with a new `id`; read it again from `acal events` before touching it.

## Subscribed calendars

```bash
acal subscribe <webcal:// or https:// address>   # opens Calendar's dialog; the user must click twice
acal calendars | jq 'select(.type=="subscription")'
acal unsubscribe <calendar id> [--yes]           # preview first, as above
acal refresh                                     # asks Calendar to reload all calendars
```

`subscribe` returns `{"status":"awaitingConfirmation"}` at once. Tell the user to confirm both windows in Calendar, then check with `acal calendars`. It cannot run unattended. These three commands need the terminal to be allowed to control Calendar (System Settings > Privacy & Security > Automation); exit code 3 means it is not.

## Cannot do

Add or answer attendees, write to subscribed or birthday calendars, search by keyword, or find free time. For the last two, list events with `acal events` and work it out with `jq`.
