function fn --description '(f)ind by (n)ame: list files whose name contains the argument'
    # usage: fn foo
    # A non-matching glob expands to nothing inside `set` (no error), which is
    # the fish analog of zsh's (N) null_glob qualifier.
    set -l matches **/*"$argv[1]"*
    if set -q matches[1]
        eza -d -- $matches
    end
end
