function site --description 'Run website (jaredeberle.org) tasks from anywhere'
    # Pure dispatch — all logic lives in $WEBSITE_REPO/scripts/, which stays
    # canonical. This just removes the `cd`. The command table lives in
    # __site_registry.fish; see the note there for why it is a table and not
    # a hand-written help string.
    set -l repo $WEBSITE_REPO
    if test -z "$repo"
        set repo $HOME/git/website
    end

    if not test -d $repo/scripts
        echo "site: no website repo at '$repo'." >&2
        echo "      Set WEBSITE_REPO to its path, or clone it to ~/git/website." >&2
        return 1
    end

    if test (count $argv) -eq 0; or contains -- $argv[1] help --help -h
        __site_usage
        return 0
    end

    set -l cmd $argv[1]

    # Resolve the command against the table, honouring aliases.
    set -l runner
    for row in (__site_registry)
        set -l field (string split \t -- $row)
        if contains -- $cmd (string split '|' -- $field[1])
            set runner $field[3]
            break
        end
    end

    if test -z "$runner"
        echo "site: '$cmd' is not a command." >&2
        # Suggest before dumping the whole list: a typo is far more common than
        # a genuine "what commands exist" question at this point.
        # Substring alone misses the most common typo there is — a transposed
        # pair, `prefligt` — so also accept a shared three-character opening,
        # which survives any mangling after the third letter.
        set -l stem (string lower -- (string sub -l 3 -- $cmd))
        set -l near
        for row in (__site_registry)
            set -l field (string split \t -- $row)
            for name in (string split '|' -- $field[1])
                if string match -qi -- "*$cmd*" $name
                    set -a near $name
                else if test (string length -- $stem) -eq 3; and string match -qi -- "$stem*" $name
                    set -a near $name
                end
            end
        end
        # Last resort, only when nothing better matched: same first letter and
        # roughly the same length. Loose enough to catch `shp` and `imgaes`,
        # and a slightly wrong guess costs nothing next to no guess at all.
        if test (count $near) -eq 0
            set -l len (string length -- $cmd)
            for row in (__site_registry)
                set -l field (string split \t -- $row)
                for name in (string split '|' -- $field[1])
                    string match -qi -- (string sub -l 1 -- $cmd)"*" $name; or continue
                    if test (math abs\((string length -- $name) - $len\)) -le 2
                        set -a near $name
                    end
                end
            end
        end

        if test (count $near) -gt 0
            echo "      Did you mean: "(string join ', ' $near)"?" >&2
        else
            echo "      Run 'site' with no arguments to see everything it can do." >&2
        end
        return 1
    end

    set -l parts (string split ' ' -- $runner)

    # Confirm the script is actually present before running it. Without this a
    # stale table produces "No such file or directory", which reads as the
    # user's mistake; this names the table instead.
    for part in $parts
        if string match -qr '\.(sh|py)$' -- $part
            if not test -f $repo/$part
                echo "site: '$cmd' runs $part, which is not in the repo." >&2
                echo "      The table in __site_registry.fish is out of date — fix it there." >&2
                return 127
            end
        end
    end

    # The scripts resolve the repo root via `git rev-parse`, so they must run
    # from inside the repo — but arguments like image files are relative to
    # the caller's cwd. Absolutize any argument that exists here; leave
    # repo-relative paths (which don't exist here) and flags untouched.
    set -l args
    for a in $argv[2..-1]
        if test -e $a
            set -a args (path resolve $a)
        else
            set -a args $a
        end
    end

    pushd $repo
    $parts $args
    set -l rc $status
    popd
    return $rc
end

function __site_usage --description 'Grouped help for `site`, rendered from __site_registry'
    set -l groups setup write reading check publish maintain
    set -l titles \
        "SETUP      start here on a new machine" \
        "WRITE      drafting and publishing a post" \
        "READING    the bibliography and reading ledger" \
        "CHECK      before you push" \
        "PUBLISH    put it live" \
        "MAINTAIN   occasional upkeep"

    echo "site — run jaredeberle.org tasks from any directory"
    echo
    echo "usage: site <command> [options]"

    # Pad the command column to the longest name actually in the table, so the
    # help stays aligned when commands are added or renamed.
    set -l width 0
    for row in (__site_registry)
        set -l field (string split \t -- $row)
        set -l name (string split '|' -- $field[1])[1]
        set -l n (string length -- $name)
        test $n -gt $width; and set width $n
    end

    for i in (seq (count $groups))
        echo
        set_color --bold
        echo "  $titles[$i]"
        set_color normal
        for row in (__site_registry)
            set -l field (string split \t -- $row)
            test "$field[2]" = "$groups[$i]"; or continue
            set -l names (string split '|' -- $field[1])
            set -l pad (string repeat -n $width ' ')

            # Line one: what it does, in plain words. Line two, dimmed: how to
            # call it. Two lines because the arguments matter far less than
            # knowing which command you want, and burying the description
            # behind a wall of <angle brackets> inverts that.
            echo "    "(string pad -r -w $width -- $names[1])"  $field[5]"

            set -l detail $field[4]
            if test (count $names) -gt 1
                set detail "$detail  (also: $names[2..-1])"
            end
            if test -n (string trim -- $detail)
                set_color brblack
                echo "    $pad  "(string trim -- $detail)
                set_color normal
            end
        end
    end

    echo
    echo "Every command passes --help through to the underlying script."
    echo "Docs: workflow.md (writing), operations.md (checks and deploys)."
end
