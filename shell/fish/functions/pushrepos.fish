function pushrepos --description 'Push every git repo under a directory that has commits ahead of its remote; errors on any repo with uncommitted changes instead of pushing it'
    # usage: pushrepos [dir]   (defaults to the current directory)
    if __help_requested $argv
        echo "usage: pushrepos [dir]   (defaults to the current directory)"
        return 0
    end

    set -l root (test (count $argv) -gt 0; and echo $argv[1]; or echo .)
    set -l had_error 0

    for entry in $root/*/
        set -l repo (string trim -r -c / -- $entry)
        test -d "$repo/.git"; or continue

        pushd "$repo" >/dev/null

        set -l dirty (git status --porcelain)
        if test (count $dirty) -gt 0
            echo "pushrepos: $repo has uncommitted changes — commit or stash before pushing" >&2
            set had_error 1
            popd >/dev/null
            continue
        end

        set -l upstream (git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
        if test -z "$upstream"
            popd >/dev/null
            continue
        end

        set -l ahead (git rev-list --count "$upstream..HEAD" 2>/dev/null)
        if test -n "$ahead" -a "$ahead" -gt 0
            echo "pushrepos: pushing $repo ($ahead commit(s) ahead of $upstream)"
            git push; or set had_error 1
        end

        popd >/dev/null
    end

    return $had_error
end
