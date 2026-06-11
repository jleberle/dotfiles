function linkcheck --description 'Check links in markdown files with lychee'
    # usage: linkcheck [file.md ...]   (no args: all *.md under the cwd)
    if not type -q lychee
        echo "linkcheck: lychee not found (run: make apps)" >&2
        return 1
    end

    set -l files $argv
    if test (count $files) -eq 0
        # Non-matching glob expands to nothing in `set` (no error).
        set files **/*.md
    end

    if test (count $files) -eq 0
        echo "linkcheck: no markdown files found" >&2
        return 1
    end

    lychee --no-progress $files
end
