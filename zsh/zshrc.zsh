
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ZSH configuration
# -------------------------------------------------------------------
source /usr/local/opt/powerlevel10k/powerlevel10k.zsh-theme

# Environment variables
if [[ -a "$HOME/.env.zsh" ]]; then
  source "$HOME/.env.zsh"
fi
export EDITOR='vim'
export PROJECTS=$HOME/Git # c + <tab> for autocomplete
export ZSH=$HOME/Git/dotfiles
export GOPATH=$HOME/go
if [[ -v NUMCORES ]]; then
  export MAKEFLAGS="-j $NUMCORES"
else
  export MAKEFLAGS="-j 4"
fi

export HOMEBREW_CASK_OPTS=--require-sha
export HOMEBREW_NO_ANALYTICS=1

#Homebrew autocompletion directories
fpath=(
 /usr/local/share/zsh-completions
 /usr/local/share/zsh/site-functions
 $fpath
)

# Sourcing Aliases and Functions
source $ZSH/zsh/aliases.zsh

# Functions
autoload -U $ZSH/zsh/functions/*(:t)

# Options
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY # adds history
setopt INC_APPEND_HISTORY SHARE_HISTORY  # adds history incrementally and share it across sessions
setopt HIST_IGNORE_ALL_DUPS  # don't record dupes in history
setopt HIST_REDUCE_BLANKS
export CLICOLOR=true
export TERM="xterm-256color"
setopt NO_BG_NICE # don't nice background tasks
setopt NO_LIST_BEEP
setopt PROMPT_SUBST
setopt CORRECT
setopt AUTO_CD
setopt COMPLETE_IN_WORD
setopt AUTOPUSHD        # keep history of directories
setopt AUTO_LIST        # list ambiguous completions automatically
setopt complete_aliases
# matches case insensitive for lowercase
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
# pasting with tabs doesn't perform completion
zstyle ':completion:*' insert-tab pending
# Vim key bindings and Vim-like line editor
bindkey -v
autoload -U   edit-command-line
zle -N        edit-command-line
bindkey -M vicmd v edit-command-line
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward
unsetopt nomatch
autoload colors zsh/terminfo && colors

# Path
# -------------------------------------------------------------------
pathdirs=(
  $HOME/Git/dotfiles/bin
  $HOME/go/bin
  $HOME/.rbenv/shims
  $HOME/.pyenv/bin
  /usr/local/sbin
  /usr/local/opt/coreutils/libexec/gnubin
  /usr/local/opt/findutils/libexec/gnubin
)

for dir in $pathdirs; do
  if [ -d $dir ]; then
    PATH=$dir:$PATH
  fi
done

# initialize autocomplete here, otherwise functions won't be loaded
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH

  autoload -Uz compinit
  compinit
fi

# Sourcing 
# -------------------------------------------------------------------
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
