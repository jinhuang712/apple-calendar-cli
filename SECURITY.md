# Security

## What `acal` can touch

`acal` can read and change everything in the user's Calendar, because that is its job. It only does so after the user allows the terminal in **System Settings → Privacy & Security → Calendars**. The subscription commands also need the terminal to be allowed to control the Calendar app.

`acal` makes no network requests of its own, and it reads no files outside the calendar store. The three subscription commands start `/usr/bin/osascript` to talk to the Calendar app; the Calendar app, not `acal`, then fetches the subscribed address.

## Reporting a problem

Please report a security problem privately, with GitHub's **Report a vulnerability** button on the repository's Security tab, and not in a public issue.

Include the command you ran and what it did that you did not expect. Do not include your own calendar data.
