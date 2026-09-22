#!/bin/bash

# Homebrew installs software meant to be world-readable, so use the standard
# umask rather than inheriting the caller's. Under launchd this is already 022,
# but the failure message below tells you to re-run this by hand — and by hand
# means from fish, where conf.d/env.fish sets 077. Without this line the same
# package gets different permissions depending on who started the update.
umask 022

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

        # --formula, NOT a bare `brew upgrade`. A bare upgrade takes
        # "installed_formula|installed_cask", so it upgrades apps in
        # /Applications too — and a launchd agent cannot do that. Two separate
        # walls, both hit on 2026-09-21 upgrading bitwarden:
        #
        #   1. sudo. Cask install ends in `sudo -E -- chgrp -hR admin <app>`,
        #      and under launchd there is no terminal to read a password from:
        #      "sudo: a terminal is required to read the password". The upgrade
        #      failed AFTER moving the new app into place, then the rollback
        #      failed too ("there is already an App at /Applications/..."),
        #      leaving Bitwarden.app owned by :staff while every other app is
        #      :admin. A half-applied upgrade is worse than no upgrade.
        #
        #   2. macOS App Management (TCC). Modifying another app's bundle needs
        #      that grant, and the process asking is Homebrew's own vendored
        #      ruby — so the denial surfaces as a "\"ruby\" was prevented from
        #      modifying apps on your Mac" notification with nothing actionable
        #      behind it. Granting it is not a fix either: the grant is tied to
        #      that binary, and `brew update` replaces portable-ruby on its own
        #      schedule (4.0.7 landed in this very run), which revokes it again.
        #
        # Neither is worth defeating. An askpass helper or a NOPASSWD sudoers
        # rule would hand every background process on this Mac the ability to
        # rewrite /Applications, to save a click on an upgrade you want to see
        # anyway. So formulae — which live in the Cellar, need no sudo and
        # touch no app bundle — are automated, and casks are reported below.
        step "Upgrading outdated packages..."  "$BREW" upgrade --formula

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

        # Casks are REPORTED, not upgraded — see the note above. This step
        # used to be `brew upgrade --cask`, which was already doing nothing:
        # the bare `brew upgrade` above had upgraded (or failed to upgrade)
        # every cask before it ran, so its output in the log was empty even on
        # the week it broke. Reporting is the honest version of that no-op.
        #
        # Most casks never appear here: brew skips `auto_updates true` ones,
        # which update themselves. What is left is the handful that genuinely
        # need you, so a weekly notification is a reminder, not noise.
        echo "Checking for outdated casks..."
        CASKS=$("$BREW" outdated --cask --quiet 2>/dev/null || true)
        if [[ -n "$CASKS" ]]; then
            N=$(grep -c . <<<"$CASKS")
            while IFS= read -r c; do echo "  $c"; done <<<"$CASKS"
            echo "  → upgrade these from a terminal (sudo + App Management both need you): brew upgrade --cask"
            osascript -e "display notification \"$N cask(s) need upgrading by hand. Run: brew upgrade --cask\" with title \"Homebrew Update\" sound name \"Glass\"" >/dev/null 2>&1 || true
        else
            echo "  none."
        fi
        echo ""

        # --prune=all removes old Cellar versions and download cache immediately
        # rather than waiting brew's default 120 days. That trades away a
        # quick `brew switch` downgrade window if an upgrade goes bad, which is
        # acceptable here since restic already backs this machine up weekly
        # (see backup/org.jaredeberle.resticcheck.plist).
        step "Cleaning up..."                  "$BREW" cleanup --prune=all
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
