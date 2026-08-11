#!/bin/sh
# mailsync — sync mail from Proton Bridge and update notmuch index
# Invoked by launchd (org.jaredeberle.mailsync); logs to ~/.local/mail_sync_logs.txt
#
# Failures are tracked, not just logged. This script used to run mbsync and
# notmuch inside a redirect block and keep no status at all, so a failure wrote
# its message into a log nobody reads and nothing else happened. That is the
# worst possible shape for mail specifically: NeoMutt showing no new messages
# looks exactly like no messages having arrived, so there is no symptom to
# notice. This machine's log had seven such failures — a wrong Maildir path
# (mail was not syncing AT ALL), DNS timeouts, and an auth failure.
#
# Because this runs every five minutes, the notification fires on the
# TRANSITION into failure, not on every failing run — a state file under
# ~/.local remembers which side of the line the last run was on. Same for the
# recovery notice. That keeps silence meaningful without making it noise.

HOMEBREW_PREFIX="/opt/homebrew"
LOG="$HOME/.local/mail_sync_logs.txt"
FAIL_STATE="$HOME/.local/.mailsync_failing"
BRIDGE_STATE="$HOME/.local/.mailsync_bridge_down"
mkdir -p "$HOME/.local"

notify() {
    osascript -e "display notification \"$1\" with title \"Mail sync\" sound name \"Basso\"" \
        >/dev/null 2>&1 || true
}

# Bridge must be running. Not an error — it is often deliberately closed — so
# this stays quiet, but the transition is recorded so the log explains a gap
# rather than just stopping.
if ! nc -z 127.0.0.1 1143 2>/dev/null; then
    if [ ! -f "$BRIDGE_STATE" ]; then
        echo "=== $(date '+%Y-%m-%d %H:%M:%S') ===" >>"$LOG"
        echo "Proton Bridge not reachable on 127.0.0.1:1143 — sync paused until it is running." >>"$LOG"
        : >"$BRIDGE_STATE"
    fi
    exit 0
fi
if [ -f "$BRIDGE_STATE" ]; then
    echo "=== $(date '+%Y-%m-%d %H:%M:%S') ===" >>"$LOG"
    echo "Proton Bridge is back — resuming sync." >>"$LOG"
    rm -f "$BRIDGE_STATE"
fi

# Keep the log from growing unbounded (runs every 5 minutes forever).
# tail, not head: this log appends, so the newest entries are at the end.
# (bin/homebrewupdate.sh caps the same way with `head` because it prepends.)
if [ -f "$LOG" ] && [ "$(wc -c <"$LOG")" -gt 1048576 ]; then
    tail -c 524288 "$LOG" >"${LOG}.tmp" && mv "${LOG}.tmp" "$LOG"
fi

failed=0

# Run one labelled step; on failure, say so in the log and count it.
step() {
    label="$1"
    shift
    [ -n "$label" ] && echo "$label"
    status=0
    "$@" 2>&1 || status=$?
    if [ "$status" -ne 0 ]; then
        echo "*** FAILED: $* (exit $status)"
        failed=$((failed + 1))
    fi
}

{
    echo "=== $(date '+%Y-%m-%d %H:%M:%S') ==="
    step "" "$HOMEBREW_PREFIX/bin/mbsync" -a
    step "" "$HOMEBREW_PREFIX/bin/notmuch" new

    if [ "$failed" -ne 0 ]; then
        echo "*** mailsync.sh: $failed step(s) FAILED — see the *** lines above."
        echo "*** Re-run by hand to watch it live: ~/git/dotfiles/bin/mailsync.sh"
    fi
} >>"$LOG"

if [ "$failed" -ne 0 ]; then
    if [ ! -f "$FAIL_STATE" ]; then
        notify "mbsync or notmuch is failing. See ~/.local/mail_sync_logs.txt"
        : >"$FAIL_STATE"
    fi
elif [ -f "$FAIL_STATE" ]; then
    notify "Mail sync is working again."
    rm -f "$FAIL_STATE"
fi

exit "$failed"
