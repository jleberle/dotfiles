function gitup --description 'Run gitup with the tracked bookmarks file'
    # No __help_requested here on purpose: this is a thin pass-through, so
    # `gitup --help` should reach the real tool's own help rather than be
    # intercepted by a wrapper that knows less about it.
    __require gitup gitup; or return 1

    command gitup -b $DOTFILES_DIR/git/gitup-bookmarks $argv
end
