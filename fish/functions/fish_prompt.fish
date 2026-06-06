function fish_prompt
    set -l last_status $status

    # Directory — truncated to 3 levels, Nord purple
    set -l dir (prompt_pwd --full-length-dirs 0 --dir-length 3)
    echo -n (set_color --bold '#B48EAD')$dir(set_color normal)

    # Git branch and status — only inside a git repo
    if command git rev-parse --is-inside-work-tree &>/dev/null
        set -l branch (command git symbolic-ref --short HEAD 2>/dev/null; or command git rev-parse --short HEAD 2>/dev/null)

        # Build status string
        set -l git_status ''
        set -l git_output (command git status --porcelain 2>/dev/null)

        set -l untracked  (string match -r '^\?\?' -- $git_output | count)
        set -l modified   (string match -r '^.M'  -- $git_output | count)
        set -l staged     (string match -r '^[MADRC]' -- $git_output | count)
        set -l deleted    (string match -r '^.D'  -- $git_output | count)

        set -l ahead  (command git rev-list --count '@{upstream}..HEAD' 2>/dev/null; or echo 0)
        set -l behind (command git rev-list --count 'HEAD..@{upstream}' 2>/dev/null; or echo 0)

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

function fish_mode_prompt
    # Vi mode indicator — show ❮ in normal mode, nothing otherwise
    if test "$fish_key_bindings" = fish_vi_key_bindings
        switch $fish_bind_mode
            case normal
                echo -n (set_color '#81A1C1')'❮ '(set_color normal)
        end
    end
end
