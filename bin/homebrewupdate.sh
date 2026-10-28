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

# Problems that are real but are NOT update failures: the update did everything
# it was asked to, and something else about the machine is wrong. Tracked apart
# from `failed` so the summary can say which, rather than signing off with
# "Brew update complete!" over an unresolved finding — the same mistake
# `make check` documents having made with its own success line.
issues=0

# Things this job found that only you can finish, from any source — app casks
# and App Store apps both land here. Collected rather than announced inline so
# one run produces ONE notification with a total, not a notification per
# subsystem. Each line is already indented for the log.
needs_hand=""

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

        # Right after the upgrade, because the upgrade is what breaks them: a
        # --user pip install is tied to python3's MINOR version, so a formula
        # upgrade that moves python3 to 3.N+1 strands every package in
        # homebrew/requirements.txt in the old ~/Library/Python/3.N/. That is
        # how the website's writing log lost PyYAML on 2026-10-26. pip skips
        # whatever is already satisfied, so on an ordinary week this is a no-op.
        # Same command as `make pydeps`; see the note there for the flags.
        REQS="$(dirname "$0")/../homebrew/requirements.txt"
        if [[ -f "$REQS" ]]; then
            step "Installing Python packages for python3..." \
                "$(dirname "$BREW")/python3" -m pip install --user --break-system-packages --quiet -r "$REQS"
        fi

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
        # Casks split two ways, by ARTIFACT rather than by name — see
        # bin/caskclassify.py for the allowlist and why it is an allowlist.
        # A cask that only drops fonts in ~/Library/Fonts or a symlink in
        # $HOMEBREW_PREFIX/bin needs no sudo and writes no app bundle, so it
        # upgrades here like a formula. Anything that installs an app (or
        # anything unrecognised) is reported for you to run by hand.
        #
        # Of the 30 casks installed when this was written, five fonts were
        # `auto` and three apps were `manual`; the other 22 never reach here
        # at all, because brew skips `auto_updates true` and `version :latest`
        # casks, which keep themselves current.
        echo "Checking for outdated casks..."
        CASKS=$("$BREW" outdated --cask --quiet 2>/dev/null || true)
        if [[ -z "$CASKS" ]]; then
            echo "  none."
            echo ""
        else
            CLASSIFY="$(dirname "$0")/caskclassify.py"
            if [[ -x "$CLASSIFY" ]]; then
                # shellcheck disable=SC2086
                # Word splitting is the point: $CASKS is a newline-separated
                # list of cask tokens, which never contain whitespace.
                CLASS=$("$CLASSIFY" $CASKS 2>/dev/null || true)
            else
                echo "*** caskclassify.py missing — treating every cask as manual"
                CLASS=$(while IFS= read -r c; do printf 'manual\t%s\tunclassified\n' "$c"; done <<<"$CASKS")
                failed=$((failed + 1))
            fi

            AUTO=$(awk -F'\t' '$1=="auto"   {print $2}' <<<"$CLASS")
            MANUAL=$(awk -F'\t' '$1=="manual" {printf "%s (%s)\n", $2, $3}' <<<"$CLASS")

            if [[ -n "$AUTO" ]]; then
                # shellcheck disable=SC2086
                step "Upgrading font/CLI casks..." "$BREW" upgrade --cask $AUTO
            fi

            if [[ -n "$MANUAL" ]]; then
                while IFS= read -r c; do
                    needs_hand+="  cask      $c"$'\n'
                done <<<"$MANUAL"
            fi
        fi

        # --prune=all removes old Cellar versions and download cache immediately
        # rather than waiting brew's default 120 days. That trades away a
        # quick `brew switch` downgrade window if an upgrade goes bad, which is
        # acceptable here since restic already backs this machine up weekly
        # (see backup/org.jaredeberle.resticcheck.plist).
        # Mac App Store apps. The Brewfile carries 20 `mas` entries and until
        # now nothing here touched them: `brew upgrade` does not, and macOS's
        # own "Automatically update apps" is unreliable — it was switched ON
        # (com.apple.commerce AutoUpdate = 1) on the machine where this was
        # written and Litterbox was still four releases behind.
        #
        # Reported, not upgraded, for the same reason app casks are: `mas
        # update` documents "Requires root privileges to update apps", and this
        # agent has no terminal to authenticate a sudo at. Attempting it anyway
        # is how a half-applied upgrade happens, which is strictly worse than a
        # skipped one. `mas outdated` is read-only and works fine as you.
        MAS="$(dirname "$BREW")/mas"
        echo "Checking for outdated App Store apps..."
        if [[ ! -x "$MAS" ]]; then
            echo "  skipped: mas not installed (it is in the Brewfile; run: make apps)"
        else
            MAS_OUT=$("$MAS" outdated 2>/dev/null || true)
            if [[ -z "$MAS_OUT" ]]; then
                echo "  none."
            else
                while IFS= read -r a; do
                    # `mas outdated` right-aligns the app id, so strip the
                    # leading padding before it goes in the shared list.
                    a="${a#"${a%%[![:space:]]*}"}"
                    [[ -n "$a" ]] || continue
                    needs_hand+="  app store $a"$'\n'
                done <<<"$MAS_OUT"
                echo "  $(grep -c . <<<"$MAS_OUT") outdated — listed below."
            fi
        fi
        echo ""

        step "Cleaning up..."                  "$BREW" cleanup --prune=all

        # Does the machine still have everything the Brewfile claims? This is
        # the check that would have caught 2026-09-21 on its own. That failed
        # cask upgrade left Bitwarden.app on disk, current and working, while
        # brew's Caskroom version directory was purged — so `brew info` said
        # "Not installed", nothing would ever upgrade it again, and the only
        # symptom was a notification about ruby. `brew outdated` cannot see a
        # package brew no longer believes in; `brew bundle check` can.
        #
        # It reuses the Brewfile rather than inventing a second inventory,
        # because this repo is the single authority on tool presence (CLAUDE.md)
        # and `make brew-check` already asks exactly this question — this just
        # asks it weekly and unattended instead of when you remember to.
        #
        # Deliberately does NOT increment `failed`: nothing about the update
        # went wrong, and folding it in would fire the "update failed" notice
        # with a message about the wrong thing. It gets its own.
        BREWFILE="$(dirname "$0")/../homebrew/brewfile"
        echo "Verifying Brewfile packages are still installed..."
        if [[ ! -f "$BREWFILE" ]]; then
            echo "  skipped: no Brewfile at $BREWFILE"
        elif BUNDLE_OUT=$("$BREW" bundle check --file="$BREWFILE" --no-upgrade --verbose 2>&1); then
            echo "  all present."
        else
            while IFS= read -r line; do echo "  $line"; done <<<"$BUNDLE_OUT"
            echo "  → a package went missing, or a cask upgrade failed halfway and"
            echo "    purged brew's record of it. Re-adopt an app that is still on"
            echo "    disk with: brew install --cask --adopt <token>"
            osascript -e "display notification \"A Brewfile package is missing or its brew record is broken. See the log.\" with title \"Homebrew Update\" sound name \"Basso\"" >/dev/null 2>&1 || true
            issues=$((issues + 1))
        fi
        echo ""

        # One report, one notification, however many subsystems contributed.
        if [[ -n "$needs_hand" ]]; then
            N=$(grep -c . <<<"$needs_hand")
            echo "Needs you — these installs are privileged and cannot run unattended:"
            printf '%s' "$needs_hand"
            echo "  → casks:     brew upgrade --cask"
            echo "  → App Store: sudo mas upgrade   (or App Store.app → Updates)"
            osascript -e "display notification \"$N update(s) need you: see ~/.local/brew_update_logs.txt\" with title \"Homebrew Update\" sound name \"Glass\"" >/dev/null 2>&1 || true
            echo ""
        fi
    fi

    if [[ $failed -eq 0 && $issues -eq 0 ]]; then
        echo "Brew update complete!"
    elif [[ $failed -eq 0 ]]; then
        echo "Brew update complete, but $issues package integrity issue(s) found — see above."
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
