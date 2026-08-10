function mkd --description 'Create a directory and cd into it'
    if __help_requested $argv
        echo "usage: mkd <dir>"
        return 0
    end

    mkdir -p $argv; and cd $argv[-1]
end
