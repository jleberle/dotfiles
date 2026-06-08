#!/bin/bash
set -euo pipefail

# Resolve brew regardless of architecture (Apple Silicon, Intel, Linux).
# Try known locations in order; fall back to PATH.
if   [[ -x /opt/homebrew/bin/brew ]]; then BREW=/opt/homebrew/bin/brew   # Apple Silicon
elif [[ -x /usr/local/bin/brew    ]]; then BREW=/usr/local/bin/brew       # Intel Mac
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then BREW=/home/linuxbrew/.linuxbrew/bin/brew
else BREW=$(command -v brew)
fi

if [[ -z $BREW ]]; then
    echo "brew not found" >&2
    exit 1
fi

# Get current date and time in format "YYYY-MM-DD @ HH:MM:SS"
TIMESTAMP=$(date "+%Y-%m-%d @ %H:%M:%S")
echo ""
echo "Executed \"homebrewupdate.sh\" at $TIMESTAMP"
echo ""

# Update Homebrew itself
echo "Updating Homebrew..."
"$BREW" update
echo ""

# Check for outdated packages
echo "Checking for outdated packages..."
"$BREW" outdated
echo ""

# Capture Hugo version before upgrade (same prefix as the detected brew)
HUGO="$(dirname "$BREW")/hugo"
HUGO_BEFORE=$("$HUGO" version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")

# Upgrade all outdated packages
echo "Upgrading outdated packages..."
"$BREW" upgrade
echo ""

# Notify if Hugo was upgraded
HUGO_AFTER=$("$HUGO" version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
if [[ -n "$HUGO_BEFORE" && -n "$HUGO_AFTER" && "$HUGO_BEFORE" != "$HUGO_AFTER" ]]; then
    echo "Hugo updated: $HUGO_BEFORE → $HUGO_AFTER"
    echo "  → run sync-hugo-version.sh (CI configs) and csp-hashes.sh --check (CSP hashes)"
    osascript -e "display notification \"Hugo $HUGO_BEFORE → $HUGO_AFTER. Run sync-hugo-version.sh + csp-hashes.sh --check.\" with title \"Homebrew Update\" sound name \"Glass\""
fi

# Upgrade outdated casks (applications)
echo "Upgrading outdated casks..."
"$BREW" upgrade --cask
echo ""

# Remove stale downloads and old versions
echo "Cleaning up..."
"$BREW" cleanup
echo ""

echo "Brew update complete!"
echo ""
echo "------------------------------------------------------------------------------"
