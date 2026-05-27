# History
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history

setopt autocd
setopt sharehistory
setopt histignoredups

# Completion
autoload -Uz compinit
compinit

# Plugins
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Prompt
eval "$(starship init zsh)"

# Aliases
alias ls="exa"
alias cat="bat"

# FZF
source <(fzf --zsh)

#Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
