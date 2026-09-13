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
#
# The log applies the same transition rule to ROUTINE runs. Logging all four
# lines of a nothing-happened run, 288 times a day, filled the 1 MB cap with
# 7,319 copies of "No new mail." in three months — so the cap was discarding
# exactly the failure history this script exists to preserve. Quiet runs are
# now counted, not written, and the streak is flushed as ONE summary line when
# something finally happens (or after 24h, so an idle week still leaves a
# heartbeat and no unexplained gap).
#
# Counted, not rewritten: collapsing the streak by editing a summary line in
# place would mean rewriting a file of up to 1 MB every five minutes — 288
# rewrites a day to avoid appending 43 KB. This stays append-only.

HOMEBREW_PREFIX="/opt/homebrew"
LOG="$HOME/.local/mail_sync_logs.txt"
FAIL_STATE="$HOME/.local/.mailsync_failing"
BRIDGE_STATE="$HOME/.local/.mailsync_bridge_down"
QUIET_STATE="$HOME/.local/.mailsync_quiet"
# Longest a streak of quiet runs may go unwritten before it is flushed anyway.
QUIET_MAX_AGE=86400
mkdir -p "$HOME/.local"

notify() {
    osascript -e "display notification \"$1\" with title \"Mail sync\" sound name \"Basso\"" \
        >/dev/null 2>&1 || true
}

# Write the pending streak of quiet runs to the log as one line, then forget it.
# Called before anything else is appended, so the log stays chronological and a
# gap between two real entries is always accounted for by the line above it.
# A no-op when no streak is pending, which is the common case.
flush_quiet() {
    [ -f "$QUIET_STATE" ] || return 0
    q_count=$(cut -d' ' -f1 "$QUIET_STATE")
    q_start=$(cut -d' ' -f2 "$QUIET_STATE")
    q_last=$(cut -d' ' -f3 "$QUIET_STATE")
    rm -f "$QUIET_STATE"
    # A truncated or hand-edited state file loses the streak rather than
    # writing a malformed line; the next quiet run starts a fresh one.
    case "$q_count$q_start$q_last" in
        '' | *[!0-9]*) return 0 ;;
    esac
    printf -- '--- %s quiet run(s), no new mail: %s .. %s ---\n' \
        "$q_count" \
        "$(date -r "$q_start" '+%Y-%m-%d %H:%M:%S')" \
        "$(date -r "$q_last" '+%Y-%m-%d %H:%M:%S')" >>"$LOG"
}

# Bridge must be running. Not an error — it is often deliberately closed — so
# this stays quiet, but the transition is recorded so the log explains a gap
# rather than just stopping.
if ! nc -z 127.0.0.1 1143 2>/dev/null; then
    if [ ! -f "$BRIDGE_STATE" ]; then
        flush_quiet
        echo "=== $(date '+%Y-%m-%d %H:%M:%S') ===" >>"$LOG"
        echo "Proton Bridge not reachable on 127.0.0.1:1143 — sync paused until it is running." >>"$LOG"
        : >"$BRIDGE_STATE"
    fi
    exit 0
fi
if [ -f "$BRIDGE_STATE" ]; then
    flush_quiet
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

# Whether the PREVIOUS run was failing, read before the notification block below
# clears the flag. A run that ends a failure streak is an event, so it is logged
# in full even though it is otherwise a quiet run — otherwise the log would show
# a failure and then nothing, and "did it recover?" would be answerable only
# from a notification that has already disappeared.
was_failing=0
[ -f "$FAIL_STATE" ] && was_failing=1

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

# Buffered rather than appended straight to the log, because whether this run is
# worth a log entry is only knowable once it has finished. A brace group is not
# a subshell in POSIX sh, so `failed` still survives the redirect.
RUN_OUT=$(mktemp)
trap 'rm -f "$RUN_OUT"' EXIT

{
    step "" "$HOMEBREW_PREFIX/bin/mbsync" -a
    step "" "$HOMEBREW_PREFIX/bin/notmuch" new

    if [ "$failed" -ne 0 ]; then
        echo "*** mailsync.sh: $failed step(s) FAILED — see the *** lines above."
        echo "*** Re-run by hand to watch it live: ~/git/dotfiles/bin/mailsync.sh"
    fi
} >"$RUN_OUT" 2>&1

# "Quiet" is notmuch's own verdict, not a guess: it prints exactly "No new mail."
# when the index did not change, and "Added N new messages..." when it did. Any
# failed step disqualifies the run regardless — a failure is never quiet.
quiet=0
if [ "$failed" -eq 0 ] && [ "$was_failing" -eq 0 ] && grep -qx 'No new mail\.' "$RUN_OUT"; then
    quiet=1
fi

now=$(date '+%s')
if [ "$quiet" -eq 1 ]; then
    if [ -f "$QUIET_STATE" ]; then
        q_n=$(cut -d' ' -f1 "$QUIET_STATE")
        q_from=$(cut -d' ' -f2 "$QUIET_STATE")
        case "$q_n$q_from" in
            '' | *[!0-9]*) q_n=0; q_from=$now ;;
        esac
    else
        q_n=0
        q_from=$now
    fi
    printf '%s %s %s\n' "$((q_n + 1))" "$q_from" "$now" >"$QUIET_STATE"

    # Flush anyway once the streak is old enough, so a genuinely idle week
    # leaves a heartbeat instead of a week-long hole. The line just written is
    # what gets flushed, so nothing is lost by writing it first.
    if [ "$((now - q_from))" -ge "$QUIET_MAX_AGE" ]; then
        flush_quiet
    fi
else
    flush_quiet
    {
        echo "=== $(date '+%Y-%m-%d %H:%M:%S') ==="
        cat "$RUN_OUT"
    } >>"$LOG"
fi

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
