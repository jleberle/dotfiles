function o --description 'Open cwd if no args, otherwise open the given paths'
    if test (count $argv) -eq 0
        open .
    else
        open $argv
    end
end
