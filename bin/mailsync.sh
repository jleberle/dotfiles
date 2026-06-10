#!/bin/sh
# mailsync — sync mail from Proton Bridge and update notmuch index
# Invoked by launchd (org.jaredeberle.mailsync); logs to ~/.local/mail_sync_logs.txt

HOMEBREW_PREFIX="$([ -d /opt/homebrew ] && echo /opt/homebrew || echo /usr/local)"
LOG="$HOME/.local/mail_sync_logs.txt"
mkdir -p "$HOME/.local"

# Bridge must be running; exit quietly instead of logging a failure every 5 min.
nc -z 127.0.0.1 1143 2>/dev/null || exit 0

# Keep the log from growing unbounded (runs every 5 minutes forever).
if [ -f "$LOG" ] && [ "$(wc -c < "$LOG")" -gt 1048576 ]; then
    tail -c 524288 "$LOG" > "${LOG}.tmp" && mv "${LOG}.tmp" "$LOG"
fi

{
    echo "=== $(date '+%Y-%m-%d %H:%M:%S') ==="
    "$HOMEBREW_PREFIX/bin/mbsync" -a 2>&1
    "$HOMEBREW_PREFIX/bin/notmuch" new 2>&1
} >> "$LOG"
