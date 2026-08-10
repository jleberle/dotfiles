function dots --description 'Run a dotfiles make target from anywhere'
    if __help_requested $argv
        echo "usage: dots <make target> [...]   (e.g. dots check, dots doctor)"
        return 0
    end

    make -C $DOTFILES_DIR $argv
end
