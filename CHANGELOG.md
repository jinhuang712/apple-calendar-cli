# Changelog

## 0.1.0 (unreleased)

- Project skeleton.
- `acal add`, `acal edit` and `acal rm` create, change and delete events, with repeat rules, alarms and per-occurrence spans. `edit` on a repeating event and `rm` only preview unless `--yes` is given.
- `acal calendars`, `acal events` and `acal event` read calendars and events as JSON.
- `acal auth` shows the calendar authorization status; `--request` shows the system prompt when the status is not determined.
