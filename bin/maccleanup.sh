#!/bin/bash

# maccleanup — report Caches usage, then purge only the package-manager caches
# that are designed to be rebuilt on demand (npm, pip, yarn, Docker build
# cache). Run by hand, not via launchd — unlike homebrewupdate.sh's weekly
# `brew cleanup`, these are triggered deliberately.
#
# Deliberately NOT here: a blanket `rm -rf ~/Library/Caches/*` (that folder is
# a grab-bag across every installed app; a few misuse it for things that
# aren't truly disposable, so wiping it all at once trades a scoped action for
# "hope nothing broke"), Xcode DerivedData (no Xcode development happens on
# this machine), and "optimization" steps like rebuilding the Spotlight index,
# repairing permissions, or purging memory — those are either no-ops on modern
# macOS (SIP already makes "repair permissions" meaningless) or diagnostic
# fixes for a specific broken symptom, not routine maintenance.
#
# Each cache step only runs if its tool is actually installed, so this stays
# a no-op section rather than a failure when e.g. Docker isn't around.

umask 022

LOG="$HOME/.local/mac_cleanup_logs.txt"
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

# Count of steps that failed, mirroring bin/homebrewupdate.sh's `step` helper
# so a broken cache command doesn't stop the rest of the run or get silently
# swallowed by `|| true`.
failed=0

step() {
    local label="$1"
    shift
    echo "$label"
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

    TIMESTAMP=$(date "+%Y-%m-%d @ %H:%M:%S")
    echo ""
    echo "Executed \"maccleanup.sh\" at $TIMESTAMP"
    echo ""

    echo "Top 20 ~/Library/Caches entries by size (report only — nothing here is deleted):"
    du -sh "$HOME"/Library/Caches/* 2>/dev/null | sort -rh | head -20
    echo ""

    if command -v npm >/dev/null 2>&1; then
        step "Cleaning npm cache..." npm cache clean --force
    fi

    if command -v pip3 >/dev/null 2>&1; then
        step "Purging pip cache..." pip3 cache purge
    elif command -v pip >/dev/null 2>&1; then
        step "Purging pip cache..." pip cache purge
    fi

    if command -v yarn >/dev/null 2>&1; then
        step "Cleaning yarn cache..." yarn cache clean
    fi

    # Only prune if the Docker daemon is actually up — `docker builder prune`
    # against a stopped daemon fails noisily and counts as a false failure.
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        step "Pruning Docker build cache..." docker builder prune --force
    fi

    if [[ $failed -eq 0 ]]; then
        echo "maccleanup complete!"
    else
        echo "*** maccleanup.sh: $failed step(s) FAILED — see the *** lines above."
    fi
    echo ""
    echo "------------------------------------------------------------------------------"

} >> "$TMPFILE" 2>&1

rc=$failed

# Show this run's output live, since (unlike homebrewupdate.sh) this script is
# meant to be watched, not just logged.
cat "$TMPFILE"

# Prepend this run's output to the top of the log so newest is always first,
# same convention as bin/homebrewupdate.sh.
mkdir -p "$(dirname "$LOG")"
if [ -s "$TMPFILE" ]; then
    if [ -f "$LOG" ]; then
        cat "$TMPFILE" "$LOG" > "${LOG}.new" && mv "${LOG}.new" "$LOG"
    else
        cp "$TMPFILE" "$LOG"
    fi
fi

# Cap the log at 1 MB, same as homebrewupdate.sh. `head`, not `tail`: newest
# entries are at the top, so the oldest history is what gets dropped.
if [ -f "$LOG" ] && [ "$(wc -c < "$LOG")" -gt 1048576 ]; then
    {
        head -c 524288 "$LOG"
        echo ""
        echo "--- older entries dropped: maccleanup.sh caps this log at 1 MB ---"
    } > "${LOG}.tmp" && mv "${LOG}.tmp" "$LOG"
fi

exit "$rc"
