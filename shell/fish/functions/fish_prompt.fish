function fish_prompt --description 'Render the prompt: truncated cwd, git branch + status, exit-colored ❯ (Nord)'
    set -l last_status $status

    # Directory — truncated to 3 levels, Nord purple
    set -l dir (prompt_pwd --full-length-dirs 0 --dir-length 0)
    echo -n (set_color --bold '#B48EAD')$dir(set_color normal)

    # Git branch and status — one `git status` call, not five.
    #
    # This used to run `rev-parse --is-inside-work-tree`, `symbolic-ref`,
    # `status --porcelain`, and TWO `rev-list --count` (ahead, behind) — five
    # forks on every single prompt, measured at ~40ms in this repo, which is
    # twice the cost of starting the entire shell. `--branch` folds the branch
    # name and both counts into the header line `status` already had to compute,
    # for no measurable extra time (21.4ms -> 20.6ms), and a non-zero exit is
    # the same "not a repo" signal `rev-parse` was being forked for.
    #
    # --ignore-submodules=dirty is the other half, and the larger one: without
    # it, `status` descends into security/betterfox on every prompt to answer a
    # question the prompt never displays. Halves the remaining call (21.4ms ->
    # 11.8ms). Submodule commit changes still show — only dirty *contents* of a
    # submodule's own work tree are skipped.
    set -l git_output (command git status --porcelain=v1 --branch --ignore-submodules=dirty 2>/dev/null)

    if test $status -eq 0
        # Header line: `## <branch>...<upstream> [ahead N, behind M]`, or
        # `## HEAD (no branch)` when detached. Split it off; the rest is files.
        set -l header $git_output[1]
        set -l files $git_output[2..]

        # Branch name: everything after `## ` up to the first `...` (the
        # upstream) or the first space (the ahead/behind bracket).
        set -l branch (string replace -r '^## ' '' -- $header)
        set branch (string split -m 1 '...' -- $branch)[1]
        set branch (string split -m 1 ' ' -- $branch)[1]
        if test "$branch" = 'HEAD'
            # Detached: `## HEAD (no branch)` carries no sha, so ask for one.
            set branch (command git rev-parse --short HEAD 2>/dev/null; or echo HEAD)
        end

        # Build status string
        set -l git_status ''

        set -l untracked (string match -r '^\?\?' -- $files | count)
        set -l modified  (string match -r '^.M'  -- $files | count)
        set -l staged    (string match -r '^[MADRC]' -- $files | count)
        set -l deleted   (string match -r '^.D'  -- $files | count)

        # Ahead/behind come out of the header's `[ahead N, behind M]` bracket
        # (absent entirely when in sync, or when there is no upstream).
        set -l ahead  (string match -rg 'ahead (\d+)'  -- $header; or echo 0)
        set -l behind (string match -rg 'behind (\d+)' -- $header; or echo 0)

        if test $staged    -gt 0; set git_status "$git_status+"; end
        if test $modified  -gt 0; set git_status "$git_status!"; end
        if test $deleted   -gt 0; set git_status "$git_status✘"; end
        if test $untracked -gt 0; set git_status "$git_status?"; end
        if test $ahead     -gt 0; set git_status "$git_status⇡"; end
        if test $behind    -gt 0; set git_status "$git_status⇣"; end

        # Branch — Nord yellow
        echo -n ' '(set_color --bold '#EBCB8B')" $branch"(set_color normal)

        # Status indicators — Nord blue
        if test -n "$git_status"
            echo -n ' '(set_color '#81A1C1')"$git_status"(set_color normal)
        end
    end

    # Prompt character — green on success, red on error
    if test $last_status -eq 0
        echo -n ' '(set_color '#A3BE8C')'❯'(set_color normal)' '
    else
        echo -n ' '(set_color '#BF616A')'❯'(set_color normal)' '
    end
end

function fish_mode_prompt --description 'Vi-mode indicator: show ❮ in normal mode, nothing otherwise (Nord)'
    # Vi mode indicator — show ❮ in normal mode, nothing otherwise
    if test "$fish_key_bindings" = fish_vi_key_bindings
        switch $fish_bind_mode
            case normal
                echo -n (set_color '#81A1C1')'❮ '(set_color normal)
        end
    end
end
