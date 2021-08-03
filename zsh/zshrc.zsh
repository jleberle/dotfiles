# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ZSH configuration
# -------------------------------------------------------------------
export CLICOLOR=true
export TERM="xterm-256color"        # for common 256 color terminals (e.g. gnome-terminal)

export DOTFILES="$HOME/.dotfiles"
export ZSH=$DOTFILES/zsh
export PROJECTS=$HOME/github

export GPG_TTY=$TTY
export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=YES
export HOMEBREW_CASK_OPTS=--require-sha
export HOMEBREW_NO_ANALYTICS=1
export GOPATH=$HOME/go

pathdirs=(
  /opt/homebrew/bin
  /opt/homebrew/sbin
  ~/go/bin
  /usr/local/opt/ruby/bin
  ~/.local/bin
  $DOTFILES/bin
)

for dir in $pathdirs; do
  if [ -d $dir ]; then
    PATH=$dir:$PATH
  fi
done

if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH

  autoload -Uz compinit
  compinit
fi

if [[ `uname` == "Darwin" ]]; then
  test -r ~/.dir_colors && eval $(gdircolors ~/.dir_colors)
else
  test -r ~/.dir_colors && eval $(dircolors ~/.dir_colors)
fi

# Options
# -------------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY # adds history
setopt INC_APPEND_HISTORY SHARE_HISTORY  # adds history incrementally and share it across sessions
setopt HIST_IGNORE_ALL_DUPS  # don't record dupes in history
setopt HIST_REDUCE_BLANKS
setopt NO_BG_NICE # don't nice background tasks
setopt NO_LIST_BEEP
setopt PROMPT_SUBST
setopt CORRECT
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

# Source Aliases and submodules
source $ZSH/aliases.zsh
source $ZSH/submodules/powerlevel10k/powerlevel10k.zsh-theme
source $ZSH/submodules/zsh-autosuggestions/zsh-autosuggestions.zsh
source $ZSH/submodules/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
