function pman --description 'Open man pages in Preview'
    man -t $argv | open -f -a Preview
end
