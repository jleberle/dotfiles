function __help_requested --description 'internal: true when a function was called with -h/--help'
    # Every user-facing function in this directory starts with:
    #
    #     if __help_requested $argv
    #         echo "usage: ..."
    #         return 0
    #     end
    #
    # It exists because `--help` used to do a different thing in every function:
    # `newdoc --help` created a file called `--help.md` and opened it in the
    # editor, `words --help` said "no such file: --help", `citecheck --help`
    # raised a Python error, and a few printed usage only because their
    # argument-count check happened to fire first. `--help` is the one thing a
    # person types when they have forgotten how a command works, so it has to
    # mean the same thing everywhere.
    #
    # Only the FIRST argument is inspected: `linkcheck --help` is a request for
    # help, but a filename literally named `--help` further along is not, and
    # neither is a flag being passed through to an underlying tool (e.g.
    # `arch grep pattern --help`, where rg should answer).
    test (count $argv) -gt 0; or return 1
    contains -- $argv[1] -h --help
end
