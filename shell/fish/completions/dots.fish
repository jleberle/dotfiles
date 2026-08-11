# Completions for `dots`, generated from the Makefile itself — the same
# `## group | description` tags `make help` renders from. A hand-written list
# here would be a third copy of the target list, and would go stale the way the
# `site` help text did.
#
# This is also the answer to "what can this repo do?" without having to know
# that `make` alone now prints it: `dots <TAB>` shows every target and purpose.

function __dots_targets
    test -n "$DOTFILES_DIR"; or return
    test -f $DOTFILES_DIR/Makefile; or return

    # Tagged targets carry their description into the completion menu.
    # Untagged .PHONY targets (the lint-* variants) are still completed, just
    # without one — omitting them would make them unreachable by tab, which is
    # the problem this file exists to fix.
    awk '
        /^[a-z][a-zA-Z0-9_-]* *:/ && /## .*\|/ {
            tgt = $0; sub(/ *:.*/, "", tgt)
            rest = substr($0, index($0, "## ") + 3)
            split(rest, p, "|"); d = p[2]
            gsub(/^ +| +$/, "", d)
            seen[tgt] = 1
            printf "%s\t%s\n", tgt, d
        }
        /^\.PHONY:/ {
            for (i = 2; i <= NF; i++) phony[$i] = 1
        }
        END {
            for (t in phony) if (!(t in seen)) printf "%s\t%s\n", t, "make target"
        }
    ' $DOTFILES_DIR/Makefile
end

complete -c dots -f
complete -c dots -n __fish_is_first_token -a '(__dots_targets)'
