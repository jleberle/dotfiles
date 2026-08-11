function o --description 'Open cwd if no args, otherwise open the given paths'
    if __help_requested $argv
        echo "usage: o [paths]   (no args: open the cwd)"
        return 0
    end

    if test (uname) != Darwin
        echo "o: macOS only — it calls the `open` command" >&2
        return 1
    end
    if test (count $argv) -eq 0
        open .
    else
        open $argv
    end
end
