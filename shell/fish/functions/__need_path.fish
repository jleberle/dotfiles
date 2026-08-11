function __need_path --description 'Return 1 with a named explanation unless a required file or directory is there'
    # usage: __need_path <caller> dir|file <label> <path> [hint]
    #
    # The sibling of __require: that one covers missing tools, this one covers
    # the configured locations they work on. Nine call sites used to spell this
    # out by hand — four verbatim copies of the archive-folder check and four
    # near-copies of the Zotero-library check, the near-copies differing only in
    # which advice they remembered to include. Same situation, four answers.
    #
    # Distinguishes "not configured" from "configured but missing", because they
    # need opposite fixes: set the variable in conf.d, versus go find the folder.
    set -l caller $argv[1]
    set -l kind $argv[2]
    set -l label $argv[3]
    set -l path $argv[4]
    set -l hint $argv[5]

    if test -z "$path"
        echo "$caller: $label is not configured — its path is empty" >&2
        echo "        (workflow locations are set in paths.env at the dotfiles repo root)" >&2
        return 1
    end

    set -l ok
    switch $kind
        case dir
            test -d "$path"; and set ok yes
        case file
            test -f "$path"; and set ok yes
        case '*'
            echo "__need_path: bad kind '$kind' (expected dir or file)" >&2
            return 2
    end

    test -n "$ok"; and return 0

    echo "$caller: $label not found: $path" >&2
    test -n "$hint"; and echo "        $hint" >&2
    return 1
end
