#!/bin/bash

# Get current date and time in format "YYYY-MM-DD @ HH:MM:SS"
TIMESTAMP=$(date "+%Y-%m-%d @ %H:%M:%S")
echo ""
echo "Executed \"homebrewupdate.sh\" at $TIMESTAMP"
echo ""

# Update Homebrew itself
echo "Updating Homebrew..."
/opt/homebrew/bin/brew update
echo ""

# Check for outdated packages
echo "Checking for outdated packages..."
/opt/homebrew/bin/brew outdated
echo ""

# Upgrade all outdated packages
echo "Upgrading outdated packages..."
/opt/homebrew/bin/brew upgrade
echo ""

# Optional: Upgrade casks (applications) as well
# echo "Upgrading outdated casks (applications)..."
# /opt/homebrew/bin/brew upgrade --cask
# echo ""

echo "Brew update complete!"
echo ""
echo "------------------------------------------------------------------------------"
