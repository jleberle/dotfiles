function pman --description 'Open man pages in Preview'
    if test (uname) != Darwin
        echo "pman is macOS only" >&2
        return 1
    end
    man -t $argv | open -f -a Preview
end
