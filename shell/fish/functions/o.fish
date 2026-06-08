function o --description 'Open cwd if no args, otherwise open the given paths'
    if test (uname) != Darwin
        echo "o is macOS only" >&2
        return 1
    end
    if test (count $argv) -eq 0
        open .
    else
        open $argv
    end
end
