function dots --description 'Run a dotfiles make target from anywhere'
    make -C $HOME/.dotfiles $argv
end
