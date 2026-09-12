#!/bin/bash

# maccleanup — report Caches/disk/backup/build-artifact usage, then purge only
# the package-manager caches that are designed to be rebuilt on demand (npm,
# pip, yarn, Docker build cache). Run by hand, not via launchd — unlike
# homebrewupdate.sh's weekly `brew cleanup`, these are triggered deliberately.
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
#
# iOS device backups are reported but never offered for scripted deletion:
# unlike node_modules/.venv (trivially rebuilt from source) or a Homebrew
# cache (redownloadable), a device backup is often the only copy of that
# data. --purge-build-artifacts intentionally covers only node_modules/.venv/
# venv, and still requires picking items by number and confirming each one.

umask 022

PURGE_BUILD_ARTIFACTS=false
for arg in "$@"; do
    case "$arg" in
        --purge-build-artifacts) PURGE_BUILD_ARTIFACTS=true ;;
        *)
            echo "Usage: $0 [--purge-build-artifacts]" >&2
            exit 1
            ;;
    esac
done

LOG="$HOME/.local/mac_cleanup_logs.txt"
TMPFILE=$(mktemp)
ARTIFACT_LIST=""
trap 'rm -f "$TMPFILE" "$ARTIFACT_LIST"' EXIT

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

# Directories that are expensive/pointless to scan for dev build artifacts:
# ~/Library is huge and never holds a project, and ~/.Trash may already
# contain half-deleted junk that shouldn't be reported as reclaimable twice.
find_build_artifacts() {
    find "$HOME" \( -path "$HOME/Library" -o -path "$HOME/.Trash" \) -prune -o \
        -type d \( -name node_modules -o -name .venv -o -name venv \) -print -prune \
        2>/dev/null
}

{
    set -uo pipefail

    TIMESTAMP=$(date "+%Y-%m-%d @ %H:%M:%S")
    echo ""
    echo "Executed \"maccleanup.sh\" at $TIMESTAMP"
    echo ""

    # -g reports directly in 1 GB (1073741824-byte) blocks, avoiding the
    # 512-byte-vs-1024-byte block-size mixup that `df -P` invites: -P's
    # "Available" column is 512-byte blocks, not KB, and dividing that by
    # 1024*1024 (as an earlier version of this script did) silently inflated
    # the free-space figure by ~2x.
    DISK_LINE=$(df -g / | awk 'NR==2')
    DISK_AVAIL_GB=$(echo "$DISK_LINE" | awk '{print $4}')
    DISK_PCT_USED=$(echo "$DISK_LINE" | awk '{print $5}' | tr -d '%')
    echo "Disk free space: ${DISK_AVAIL_GB}G available (${DISK_PCT_USED}% used)"
    if [ "$DISK_PCT_USED" -ge 85 ]; then
        echo "WARNING: disk is ${DISK_PCT_USED}% full — APFS performance degrades as free space runs low."
    fi
    echo ""

    echo "Top 20 ~/Library/Caches entries by size (report only — nothing here is deleted):"
    du -sh "$HOME"/Library/Caches/* 2>/dev/null | sort -rh | head -20
    echo ""

    BACKUP_DIR="$HOME/Library/Application Support/MobileSync/Backup"
    if [ -d "$BACKUP_DIR" ]; then
        echo "iOS device backups (report only — these are not redownloadable, delete manually via Finder if unwanted):"
        for d in "$BACKUP_DIR"/*/; do
            [ -d "$d" ] || continue
            name=""
            # PlistBuddy prints "File Doesn't Exist" to stdout (not stderr) when
            # the plist is missing, so guard with -f rather than relying on 2>/dev/null.
            if [ -f "$d/Info.plist" ]; then
                name=$(/usr/libexec/PlistBuddy -c "Print :Display Name" "$d/Info.plist" 2>/dev/null)
            fi
            size=$(du -sh "$d" 2>/dev/null | cut -f1)
            printf '%s\t%s\n' "${size:-?}" "${name:-$(basename "$d")}"
        done | sort -rh
        echo ""
    fi

    echo "Top 20 reclaimable dev build artifacts under \$HOME (node_modules, .venv, venv — report only):"
    while IFS= read -r d; do
        size=$(du -sh "$d" 2>/dev/null | cut -f1)
        printf '%s\t%s\n' "${size:-?}" "$d"
    done < <(find_build_artifacts) | sort -rh | head -20
    if $PURGE_BUILD_ARTIFACTS; then
        echo "(--purge-build-artifacts requested — review list below after this report)"
    fi
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

# Interactive purge, run live against the terminal rather than inside the
# logged/redirected block above (a `read` prompt needs visible stdout, which
# the block's `>> "$TMPFILE"` redirection swallows). Requires a real terminal
# so this is never accidentally triggered by some future automated caller.
if $PURGE_BUILD_ARTIFACTS; then
    if [ ! -t 0 ]; then
        echo "--purge-build-artifacts requires an interactive terminal; skipping." >&2
        exit "$rc"
    fi

    ARTIFACT_LIST=$(mktemp)
    while IFS= read -r d; do
        size=$(du -sh "$d" 2>/dev/null | cut -f1)
        printf '%s\t%s\n' "${size:-?}" "$d"
    done < <(find_build_artifacts) | sort -rh > "$ARTIFACT_LIST"

    COUNT=$(wc -l < "$ARTIFACT_LIST" | tr -d ' ')
    if [ "$COUNT" -eq 0 ]; then
        echo "No node_modules/.venv/venv directories found."
        exit "$rc"
    fi

    echo ""
    echo "Build artifacts found (all rebuildable from source):"
    nl -ba -w2 -s') ' "$ARTIFACT_LIST"
    echo ""
    printf "Enter numbers to delete (e.g. '1 3 5'), 'all', or press Enter to skip: "
    read -r SELECTION
    if [ -z "$SELECTION" ]; then
        echo "Skipped."
        exit "$rc"
    fi
    if [ "$SELECTION" = "all" ]; then
        SELECTION=$(seq 1 "$COUNT")
    fi

    for n in $SELECTION; do
        line=$(sed -n "${n}p" "$ARTIFACT_LIST")
        [ -z "$line" ] && continue
        path=$(printf '%s' "$line" | cut -f2)
        size=$(printf '%s' "$line" | cut -f1)
        printf 'Delete %s (%s)? [y/N] ' "$path" "$size"
        read -r CONFIRM
        case "$CONFIRM" in
            y|Y) rm -rf -- "$path" && echo "Removed $path" ;;
            *) echo "Skipped $path" ;;
        esac
    done
fi

exit "$rc"
