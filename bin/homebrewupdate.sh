#!/bin/bash

LOG="$HOME/.local/brew_update_logs.txt"
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

# Count of steps that failed. The block below used to open with `set -euo
# pipefail` and end with `|| true`, which looked like "abort on error, then
# ignore it" but did neither: a compound command on the left of `||` runs with
# errexit SUPPRESSED, so every step ran regardless of failure and the group's
# status was just that of the final `echo` — always 0. A tap going away or a
# cask refusing to upgrade left "Brew update complete!" in the log, launchd
# recorded success, and the only symptom was updates quietly not happening.
#
# So failures are now tracked explicitly, per step, by `step` below. Continuing
# after one is deliberate: a broken cask should not stop `brew cleanup`.
failed=0

# Run one labelled step; on failure, say so in the log and count it.
step() {
    local label="$1"
    shift
    echo "$label"
    # Capture the status into a variable rather than reading $? after `if !`,
    # where the negation has already rewritten it to 0.
    local status=0
    "$@" || status=$?
    if [[ $status -ne 0 ]]; then
        echo "*** FAILED: $* (exit $status)"
        failed=$((failed + 1))
    fi
    echo ""
}

{
    set -uo pipefail

    # Apple Silicon Homebrew; fall back to PATH so the "brew not found" guard fires.
    if [[ -x /opt/homebrew/bin/brew ]]; then BREW=/opt/homebrew/bin/brew
    else BREW=$(command -v brew || true)
    fi

    TIMESTAMP=$(date "+%Y-%m-%d @ %H:%M:%S")
    echo ""
    echo "Executed \"homebrewupdate.sh\" at $TIMESTAMP"
    echo ""

    if [[ -z $BREW ]]; then
        echo "*** FAILED: brew not found"
        failed=1
    else
        step "Updating Homebrew..."            "$BREW" update
        step "Checking for outdated packages..." "$BREW" outdated

        # Capture Hugo version before upgrade
        HUGO="$(dirname "$BREW")/hugo"
        HUGO_BEFORE=$("$HUGO" version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")

        step "Upgrading outdated packages..."  "$BREW" upgrade

        # Notify if Hugo was upgraded. Both follow-ups are `site` subcommands
        # now, so they run from anywhere — no `cd` into the website repo.
        HUGO_AFTER=$("$HUGO" version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
        if [[ -n "$HUGO_BEFORE" && -n "$HUGO_AFTER" && "$HUGO_BEFORE" != "$HUGO_AFTER" ]]; then
            FOLLOWUP="site hugo-version && site csp --write"
            echo "Hugo updated: $HUGO_BEFORE → $HUGO_AFTER"
            echo "  → run: $FOLLOWUP"
            osascript -e "display notification \"Hugo $HUGO_BEFORE → $HUGO_AFTER. Run: site hugo-version && site csp --write\" with title \"Homebrew Update\" sound name \"Glass\""
            echo ""
        fi

        step "Upgrading outdated casks..."     "$BREW" upgrade --cask
        step "Cleaning up..."                  "$BREW" cleanup
    fi

    if [[ $failed -eq 0 ]]; then
        echo "Brew update complete!"
    else
        echo "*** homebrewupdate.sh: $failed step(s) FAILED — see the *** lines above."
        echo "*** Re-run by hand to watch it live: ~/git/dotfiles/bin/homebrewupdate.sh"
    fi
    echo ""
    echo "------------------------------------------------------------------------------"

} >> "$TMPFILE" 2>&1

rc=$failed

# Prepend this run's output to the top of the log so newest is always first
mkdir -p "$(dirname "$LOG")"
if [ -s "$TMPFILE" ]; then
    if [ -f "$LOG" ]; then
        cat "$TMPFILE" "$LOG" > "${LOG}.new" && mv "${LOG}.new" "$LOG"
    else
        cp "$TMPFILE" "$LOG"
    fi
fi

# Keep the log from growing unbounded. This replaces homebrewlogclean.sh and its
# own launchd agent — ten lines, a plist, a Makefile target, a shellcheck entry
# and a doctor entry, all to delete one file on the first Monday of the month.
# Capping here is the pattern mailsync.sh already uses, minus the moving parts,
# and the log can no longer be wiped just before the run you wanted to read.
#
# `head`, not `tail`: this log is written newest-first, so the oldest entries are
# at the END. The note goes where the discarded history used to be.
if [ -f "$LOG" ] && [ "$(wc -c < "$LOG")" -gt 1048576 ]; then
    {
        head -c 524288 "$LOG"
        echo ""
        echo "--- older entries dropped: homebrewupdate.sh caps this log at 1 MB ---"
    } > "${LOG}.tmp" && mv "${LOG}.tmp" "$LOG"
fi

# Same notification path the Hugo-upgrade notice already uses. Without this the
# only signal of a broken weekly update is its absence, which is not a signal.
if [ "$rc" -ne 0 ]; then
    osascript -e 'display notification "Update failed — see ~/.local/brew_update_logs.txt (newest run first)." with title "Homebrew Update FAILED" sound name "Basso"' >/dev/null 2>&1 || true
fi

exit "$rc"
