function linkcheck --description 'Check links in markdown files with lychee'
    # usage: linkcheck [--yes] [file.md ...]   (no args: all *.md under the cwd)
    if __help_requested $argv
        echo "usage: linkcheck [--yes] [file.md ...]   (no args: all *.md under the cwd)"
        echo "  --yes  skip the confirmation on a large recursive run"
        return 0
    end

    __require linkcheck lychee; or return 1

    set -l assume_yes false
    if test "$argv[1]" = --yes; or test "$argv[1]" = -y
        set assume_yes true
        set argv $argv[2..-1]
    end

    set -l files $argv
    set -l recursive false
    if test (count $files) -eq 0
        # Non-matching glob expands to nothing in `set` (no error).
        set files **/*.md
        set recursive true
    end

    if test (count $files) -eq 0
        echo "linkcheck: no markdown files found" >&2
        return 1
    end

    # With no arguments this globs the whole tree and hits every URL in it over
    # the network. Run in ~ or a vault root that is thousands of files, and it
    # looks hung for a very long time with no way to know what it is doing.
    # Print the count first, and confirm before a big one — but only for the
    # recursive form: an explicit file list is exactly what was asked for.
    echo "linkcheck: checking "(count $files)" file(s)"
    if $recursive; and test (count $files) -gt 50; and not $assume_yes
        read -l -P "That will make a lot of network requests. Continue? [y/N] " reply
        if not string match -qi 'y*' -- $reply
            echo "linkcheck: cancelled" >&2
            return 1
        end
    end

    lychee --no-progress $files
end
