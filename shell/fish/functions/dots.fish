function dots --description 'Run a dotfiles make target from anywhere'
    make -C $DOTFILES_DIR $argv
end
