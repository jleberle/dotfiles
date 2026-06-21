function fish_should_add_to_history --description 'Keep secrets and space-prefixed commands out of fish_history'
    # fish has no HISTIGNORESPACE/HISTIGNORE; this is the supported hook (fish 3.4+).
    # Return 1 to exclude the command line from ~/.local/share/fish/fish_history
    # (which is plaintext and effectively unbounded here).
    set -l cmd $argv[1]

    # Leading whitespace → opt out of history for this command (the HISTIGNORESPACE
    # behavior the options.fish notes called out as missing).
    if string match -qr '^\s' -- $cmd
        return 1
    end

    # Heuristic secret guard: skip lines that look like they carry a credential
    # inline. Deliberately conservative — widen if you find leaks slipping through.
    if string match -qr -- '(?i)(password|passwd|secret|token|api[_-]?key|--pass\b|RESTIC_PASSWORD)' -- $cmd
        return 1
    end

    return 0
end
