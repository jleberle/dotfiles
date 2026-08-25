function gitstatus --description 'Show which git repos under a directory have uncommitted changes or unpushed commits'
    # usage: gitstatus [dir]   (defaults to ~/git)
    if __help_requested $argv
        echo "usage: gitstatus [dir]   (defaults to ~/git)"
        return 0
    end

    set -l root (test (count $argv) -gt 0; and echo $argv[1]; or echo ~/git)
    set -l clean_count 0
    set -l attention_count 0

    for entry in $root/*/
        set -l repo (string trim -r -c / -- $entry)
        test -d "$repo/.git"; or continue

        pushd "$repo" >/dev/null

        set -l name (basename "$repo")
        set -l branch (git rev-parse --abbrev-ref HEAD 2>/dev/null)
        set -l dirty (git status --porcelain)
        set -l notes

        if test (count $dirty) -gt 0
            set -a notes (printf '%d uncommitted change(s)' (count $dirty))
        end

        set -l upstream (git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
        if test -n "$upstream"
            set -l ahead (git rev-list --count "$upstream..HEAD" 2>/dev/null)
            set -l behind (git rev-list --count "HEAD..$upstream" 2>/dev/null)
            test -n "$ahead" -a "$ahead" -gt 0; and set -a notes "$ahead ahead of $upstream"
            test -n "$behind" -a "$behind" -gt 0; and set -a notes "$behind behind $upstream"
        else
            set -a notes "no upstream"
        end

        if test (count $notes) -gt 0
            set attention_count (math $attention_count + 1)
            printf '%-20s [%s] %s\n' "$name" "$branch" (string join ', ' $notes)
        else
            set clean_count (math $clean_count + 1)
        end

        popd >/dev/null
    end

    echo "---"
    echo "$clean_count clean, $attention_count need attention"
end
