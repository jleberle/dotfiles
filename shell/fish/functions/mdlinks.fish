function mdlinks --description 'Markdown reference links for every open browser tab'
    # usage: mdlinks safari | mdlinks firefox
    #
    # Replaces the two `md - Links - * Tabs` Automator Services (Brett Terpstra's
    # Markdown Service Tools). Those declared `service input: nothing` and
    # `service output: text`, meaning they typed their result at the cursor of a
    # GUI text field — unreachable from a draft open in Neovim, which is the same
    # reason docs/automation.md gives for deleting the rest of that suite. This
    # writes to stdout instead, so it composes:
    #
    #     mdlinks firefox | pbcopy
    #     mdlinks safari >> notes.md
    #
    # The logic lives in bin/mdlinks.py; this collects the tabs and hands them over.
    if __help_requested $argv
        echo "usage: mdlinks safari    reference links for every open Safari tab"
        echo "       mdlinks firefox   same for every open Firefox tab"
        echo ""
        echo "Writes Markdown reference definitions to stdout, sorted by label:"
        echo "  [jstor]: https://www.jstor.org/stable/1234567"
        echo ""
        echo "Paste into a draft with:  mdlinks firefox | pbcopy"
        return 0
    end

    if test (count $argv) -ne 1
        echo "usage: mdlinks <safari|firefox>" >&2
        return 1
    end

    switch $argv[1]
        case safari
            # pgrep rather than asking System Events: `tell application "Safari"`
            # LAUNCHES Safari when it isn't running, so collecting tabs would
            # start a browser. pgrep also avoids an Automation TCC prompt.
            if not pgrep -x Safari >/dev/null 2>&1
                echo "mdlinks: Safari is not running" >&2
                return 1
            end
            # Every window. The Ruby original read `every tab of window 1`, so a
            # second window's tabs were silently missing from the list.
            osascript -e '
                set out to ""
                tell application "Safari"
                    repeat with w in windows
                        repeat with t in tabs of w
                            set out to out & (URL of t) & linefeed
                        end repeat
                    end repeat
                end tell
                return out' 2>/dev/null | $DOTFILES_DIR/bin/mdlinks.py

        case firefox
            set -l ffdir "$HOME/Library/Application Support/Firefox"
            set -l profile (awk -F= '/^Default=/{print $2; exit}' "$ffdir/installs.ini" 2>/dev/null)
            if test -z "$profile"
                echo "mdlinks: no default Firefox profile found — launch Firefox once" >&2
                return 1
            end

            # recovery.jsonlz4 is the live session, rewritten every few seconds.
            # On a clean quit Firefox moves it to previous.jsonlz4, so fall back
            # to that rather than reporting nothing after you close the browser.
            set -l session "$ffdir/$profile/sessionstore-backups/recovery.jsonlz4"
            if not test -f "$session"
                set session "$ffdir/$profile/sessionstore-backups/previous.jsonlz4"
            end
            if not test -f "$session"
                echo "mdlinks: no Firefox session store under $ffdir/$profile" >&2
                echo "         (start Firefox and try again)" >&2
                return 1
            end

            $DOTFILES_DIR/bin/mdlinks.py --firefox "$session"

        case '*'
            echo "mdlinks: unknown browser '$argv[1]' — expected safari or firefox" >&2
            return 1
    end
end
