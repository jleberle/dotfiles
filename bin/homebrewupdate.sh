#!/bin/bash

LOG="$HOME/.local/brew_update_logs.txt"
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

{
    set -euo pipefail

    # Resolve brew regardless of architecture (Apple Silicon, Intel, Linux).
    if   [[ -x /opt/homebrew/bin/brew ]]; then BREW=/opt/homebrew/bin/brew
    elif [[ -x /usr/local/bin/brew    ]]; then BREW=/usr/local/bin/brew
    elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then BREW=/home/linuxbrew/.linuxbrew/bin/brew
    else BREW=$(command -v brew)
    fi

    if [[ -z $BREW ]]; then
        echo "brew not found" >&2
        exit 1
    fi

    TIMESTAMP=$(date "+%Y-%m-%d @ %H:%M:%S")
    echo ""
    echo "Executed \"homebrewupdate.sh\" at $TIMESTAMP"
    echo ""

    echo "Updating Homebrew..."
    "$BREW" update
    echo ""

    echo "Checking for outdated packages..."
    "$BREW" outdated
    echo ""

    # Capture Hugo version before upgrade
    HUGO="$(dirname "$BREW")/hugo"
    HUGO_BEFORE=$("$HUGO" version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")

    echo "Upgrading outdated packages..."
    "$BREW" upgrade
    echo ""

    # Notify if Hugo was upgraded. The follow-ups live in ~/git/website/scripts/
    # (sync-hugo-version.sh, csp-hashes.sh), reachable via the `site` fish function.
    HUGO_AFTER=$("$HUGO" version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
    if [[ -n "$HUGO_BEFORE" && -n "$HUGO_AFTER" && "$HUGO_BEFORE" != "$HUGO_AFTER" ]]; then
        echo "Hugo updated: $HUGO_BEFORE → $HUGO_AFTER"
        echo "  → run: site sync-hugo && site csp"
        osascript -e "display notification \"Hugo $HUGO_BEFORE → $HUGO_AFTER. Run: site sync-hugo && site csp.\" with title \"Homebrew Update\" sound name \"Glass\""
    fi

    echo "Upgrading outdated casks..."
    "$BREW" upgrade --cask
    echo ""

    echo "Cleaning up..."
    "$BREW" cleanup
    echo ""

    echo "Brew update complete!"
    echo ""
    echo "------------------------------------------------------------------------------"

} >> "$TMPFILE" 2>&1 || true

# Prepend this run's output to the top of the log so newest is always first
mkdir -p "$(dirname "$LOG")"
if [ -s "$TMPFILE" ]; then
    if [ -f "$LOG" ]; then
        cat "$TMPFILE" "$LOG" > "${LOG}.new" && mv "${LOG}.new" "$LOG"
    else
        cp "$TMPFILE" "$LOG"
    fi
fi
