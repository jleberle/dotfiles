#!/bin/bash

# Get the current day of the week (1 = Monday, 7 = Sunday)
DAY_OF_WEEK=$(date +%u)

# Get the current day of the month
DAY_OF_MONTH=$(date +%d)

# Check if it's the first Monday of the month
if [ "$DAY_OF_WEEK" -eq 1 ] && [ "$DAY_OF_MONTH" -le 7 ]; then
  rm -f ~/.local/brew_update_logs.txt
fi
