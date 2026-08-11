function acp --description 'All-in-one Git: add, signed commit, push'
    # usage: acp [--yes] <commit message>   (quotes optional)
    if __help_requested $argv
        echo "usage: acp [--yes] <commit message>   (quotes optional)"
        echo "  --yes  skip the confirmation on an unusually large commit"
        return 0
    end

    set -l assume_yes false
    if test "$argv[1]" = --yes; or test "$argv[1]" = -y
        set assume_yes true
        set argv $argv[2..-1]
    end

    if test (count $argv) -eq 0
        echo "usage: acp [--yes] <commit message>" >&2
        return 1
    end

    git add .

    if git diff --cached --quiet
        echo "Nothing to commit." >&2
        return 1
    end

    # This is `git add .` — deliberately, it's a speed tool — so what gets
    # committed depends entirely on the cwd being right. Print the list so a
    # wrong `cd` is visible in scrollback and can be undone immediately.
    set -l staged (git diff --cached --name-only)
    printf '%s\n' $staged | sed 's/^/  /'
    echo (count $staged)" file(s) staged"

    # Confirm only above a threshold. A prompt on every commit would defeat the
    # point of the command, and normal work here is a handful of files; the
    # failure this catches — running in ~ or a vault root and sweeping in a tree
    # that was never meant to be in this repo — always stages far more than that.
    if test (count $staged) -gt 25; and not $assume_yes
        read -l -P "That is a lot of files. Commit and push them? [y/N] " reply
        if not string match -qi 'y*' -- $reply
            git reset >/dev/null
            echo "Cancelled — nothing committed, staging area reset." >&2
            return 1
        end
    end

    # Signing is handled globally by gitconfig (commit.gpgsign = true).
    git commit -m "$argv" \
        && git push
end
