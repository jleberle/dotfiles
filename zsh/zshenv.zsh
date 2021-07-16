#!/bin/zsh
###############################
# EXPORT ENVIRONMENT VARIABLE #
###############################
export CLICOLOR=true
export TERM="xterm-256color"        # for common 256 color terminals (e.g. gnome-terminal)

export DOTFILES="$HOME/Dropbox/Dotfiles"
export ZSH=$DOTFILES/zsh

export GPG_TTY=$TTY
export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=YES
export HOMEBREW_CASK_OPTS=--require-sha
export HOMEBREW_NO_ANALYTICS=1
export GOPATH=$HOME/go

if [[ -v NUMCORES ]]; then
  export MAKEFLAGS="-j $NUMCORES"
else
  export MAKEFLAGS="-j 4"
fi
