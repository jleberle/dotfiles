#!/bin/sh
# mailsync — sync mail from mailbox.org and update notmuch index
# Invoked by launchd (org.jaredeberle.mailsync); logs to ~/.local/mail_sync_logs.txt

HOMEBREW_PREFIX="$([ -d /opt/homebrew ] && echo /opt/homebrew || echo /usr/local)"
LOG="$HOME/.local/mail_sync_logs.txt"
mkdir -p "$HOME/.local"

{
    echo "=== $(date '+%Y-%m-%d %H:%M:%S') ==="
    "$HOMEBREW_PREFIX/bin/mbsync" -a 2>&1
    "$HOMEBREW_PREFIX/bin/notmuch" new 2>&1
} >> "$LOG"
