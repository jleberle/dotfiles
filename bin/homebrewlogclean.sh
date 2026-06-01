#!/bin/bash
set -euo pipefail

# Launchd schedules this on Mondays, so only the "first of the month" guard
# is needed here — the day-of-week check is redundant.
DAY_OF_MONTH=$(date +%d)

if [ "$DAY_OF_MONTH" -le 7 ]; then
  rm -f "$HOME/.local/brew_update_logs.txt"
fi
