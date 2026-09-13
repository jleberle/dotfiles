function brew --description 'Run Homebrew with umask 022 so the Cellar stays world-readable'
    # No __help_requested here on purpose: this is a thin pass-through, so
    # `brew --help` should reach the real tool's own help rather than be
    # intercepted by a wrapper that knows less about it. Same reasoning as
    # gitup.fish.
    #
    # WHY THIS EXISTS. conf.d/env.fish sets `umask 077` for every fish session,
    # which is right for everything you create — and wrong for the one program
    # that installs software meant to be readable by other accounts. brew
    # creates Cellar directories with the caller's umask, so every package
    # installed by hand from a fish prompt landed as drwx------ while the same
    # package installed by the weekly launchd job landed as drwxr-xr-x. Nothing
    # breaks while brew runs as you, which is exactly the problem: 32 version
    # directories (25,394 entries beneath them) had drifted before `make
    # brew-check` was taught to look, and the only way to discover it otherwise
    # is a second account failing to run `fish`, `gh`, `node` or `tmux` --
    # every one of those symlinks into a Cellar directory it could not traverse.
    #
    # `make apps` and bin/homebrewupdate.sh already set umask 022; both run
    # under /bin/sh, outside this function, so they still need their own. This
    # covers the third path, the interactive one, which is where the drift
    # actually came from.
    #
    # NOT `__require brew brew`: `__require` tests with `type -q`, and this
    # function IS named brew, so that check can never fail. `command -q` asks
    # the question that was meant -- is there a real brew on PATH.
    command -q brew; or begin
        echo "brew: not installed (see README bootstrap, or /opt/homebrew/bin/brew)" >&2
        return 127
    end

    # Scoped to brew's own process, not the session. Setting `umask 022` in the
    # function body and restoring it afterwards would be the obvious shape, but
    # fish's umask is process-global and a Ctrl-C mid-install can abort the
    # function before the restore runs -- leaving the shell's defense-in-depth
    # umask silently weakened for the rest of the session. `sh -c` sets it in a
    # child that then execs brew, so this shell's own umask is never touched.
    # $argv passes through argv rather than a quoted string, so filenames with
    # spaces survive, and `exec` keeps brew on the same tty (cask installs
    # prompt for sudo, and `brew` pages its own help).
    command sh -c 'umask 022; exec "$@"' sh (command -v brew) $argv
end
