# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ZSH configuration
# -------------------------------------------------------------------
export EDITOR='nvim'
export PROJECTS=$HOME/Git # c + <tab> for autocomplete
export ZSH=$HOME/Git/dotfiles
export TROPY_PATH=/opt/tropy

# Sourcing Aliases and Functions
source $ZSH/zsh/debian-aliases.zsh

# Functions
autoload -U $ZSH/zsh/functions/*(:t)

# Colors
eval $(dircolors "$ZSH/zsh/solarized-colors")

# Options
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY # adds history
setopt INC_APPEND_HISTORY SHARE_HISTORY  # adds history incrementally and share it across sessions
setopt HIST_IGNORE_ALL_DUPS  # don't record dupes in history
setopt HIST_REDUCE_BLANKS
export CLICOLOR=true
export TERM="xterm-256color"        # for common 256 color terminals (e.g. gnome-terminal)
export TERM="screen-256color"       # for a tmux -2 session (also for screen)
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
  $HOME/.gem/ruby/2.5.0/bin
  $HOME/.local/bin
  $TROPY_PATH
)

for dir in $pathdirs; do
  if [ -d $dir ]; then
    PATH=$dir:$PATH
  fi
done

autoload -Uz compinit
compinit

# Sourcing 
# -------------------------------------------------------------------
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
source ~/.config/powerlevel10k/powerlevel10k.zsh-theme
GPG_TTY=$(tty)
export GPG_TTY
