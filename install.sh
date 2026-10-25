#!/bin/sh
# Installs the apple-calendar skill for Claude Code.
#   curl -fsSL https://raw.githubusercontent.com/jinhuang712/apple-calendar-cli/master/install.sh | sh
# ACAL_RAW_BASE changes where the skill is fetched from, and CLAUDE_CONFIG_DIR where it is installed.
set -eu

base="${ACAL_RAW_BASE:-https://raw.githubusercontent.com/jinhuang712/apple-calendar-cli/master}"
dest="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/apple-calendar"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

curl -fsSL "$base/skills/apple-calendar/SKILL.md" -o "$tmp"
if ! head -n 1 "$tmp" | grep -q '^---$'; then
  echo "The downloaded file is not a skill. Nothing was installed." >&2
  exit 1
fi

mkdir -p "$dest"
cp "$tmp" "$dest/SKILL.md"
chmod 644 "$dest/SKILL.md"
echo "Installed the apple-calendar skill to $dest/SKILL.md"

if ! command -v acal >/dev/null 2>&1; then
  echo "Note: the acal command is not on your PATH yet. The skill needs it; see the project README."
fi
