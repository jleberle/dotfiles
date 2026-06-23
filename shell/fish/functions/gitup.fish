function gitup --description 'Run gitup with the tracked bookmarks file'
    command gitup -b $DOTFILES_DIR/git/gitup-bookmarks $argv
end
