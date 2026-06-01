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

# Upgrade all outdated packages
echo "Upgrading outdated packages..."
"$BREW" upgrade
echo ""

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
