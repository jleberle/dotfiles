function cdf --description 'cd to the top-most Finder window location'
    if __help_requested $argv
        echo "usage: cdf   (no arguments)"
        return 0
    end

    if test (uname) != Darwin
        echo "cdf is macOS only" >&2
        return 1
    end
    set -l dir (osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)' 2>/dev/null)
    if test -z "$dir"
        echo "No Finder window open" >&2
        return 1
    end
    cd $dir
end
