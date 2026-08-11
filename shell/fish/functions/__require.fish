function __require --description 'Return 1 with an install hint unless every named command is present'
    # usage: __require <caller> <command>...
    #
    # Every function that shells out to a Homebrew-installed tool starts with
    # this. It exists because the handling used to be a coin flip: six functions
    # checked and printed "brew install X", seven others let fish emit a bare
    # "Unknown command", so you could not predict which of two commands from the
    # same repo would explain itself.
    #
    # Reports *every* missing command, not just the first — `cite` needs both rg
    # and fzf, and finding that out one `brew install` at a time is needless.
    #
    # The hints name the formula rather than saying "make apps" because that
    # installs the whole brewfile. Everything below is in homebrew/brewfile, so
    # `make apps` is always a correct answer too, just a much bigger one.
    set -l caller $argv[1]

    set -l missing
    for cmd in $argv[2..-1]
        type -q $cmd; or set -a missing $cmd
    end

    test (count $missing) -eq 0; and return 0

    for cmd in $missing
        # Only the cases where the command name differs from the formula name
        # need a row; the fallthrough covers the majority where they match.
        set -l hint
        switch $cmd
            case rga
                set hint "brew install ripgrep-all"
            case rg
                set hint "brew install ripgrep"
            case pdftotext
                set hint "brew install poppler"
            case mbsync
                set hint "brew install isync"
            case bbedit
                # A cask, and the CLI tool is a separate opt-in inside the app.
                set hint "brew install --cask bbedit, then BBEdit > Install Command Line Tools"
            case '*'
                set hint "brew install $cmd"
        end
        echo "$caller: $cmd not found — $hint" >&2
    end

    return 1
end
