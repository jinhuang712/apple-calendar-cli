# Contributing

Thanks for helping. This is a small tool, so the process is small too.

## Build and test

You need macOS 14 or later and a Swift toolchain.

```bash
swift build
swift test
swiftlint lint --strict
```

The unit tests need no calendar access. Commands that read or write the calendar can only be checked by hand, against a real calendar.

## Checking a change by hand

- Allow your terminal in **System Settings → Privacy & Security → Calendars**, then run the command.
- When a command writes, give the event an obvious temporary title such as `ZZ-test`, put it in a calendar you do not mind touching, and delete it afterwards. Check that nothing was left behind.
- Never paste your own calendar names, event titles or ids into an issue or a pull request.

## Before you open a pull request

- Read [DESIGNS.md](DESIGNS.md). It lists the three principles the tool is built around, and what each one rules out. A change that goes against one needs a reason.
- Read the matching entry in [FEATURES.md](FEATURES.md). It says what a command does and what it deliberately does not. If your change moves a command's behavior, update that entry in the same pull request.
- Add a line to [CHANGELOG.md](CHANGELOG.md).
- Keep a pull request to one change. Small commits are easier to review.

## Reporting a bug

Say which command you ran, what you expected, and what you got, including the exit code. Remove personal data from any output you paste.
