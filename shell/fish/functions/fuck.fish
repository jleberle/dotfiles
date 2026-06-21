function fuck --description 'Re-run the previous command under sudo (after confirmation)'
    # $history[1] is the most recent command line in an interactive session.
    set -l cmd $history[1]

    # Guard an empty history and the off-by-one where $history[1] is `fuck` itself.
    if test -z "$cmd"; or test "$cmd" = fuck
        echo "fuck: no previous command to re-run" >&2
        return 1
    end

    # Show exactly what will run as root before authorizing it: `sudo fish -c`
    # re-parses the command in a root context, so command substitutions and globs
    # are recomputed with root's view of the system — confirm before that happens.
    read -l -P "sudo: $cmd  [y/N] " reply
    if test "$reply" = y -o "$reply" = Y
        sudo fish -c "$cmd"
    else
        echo "aborted" >&2
        return 1
    end
end
