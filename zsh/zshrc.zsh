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

# Aliases
# --------------------------------------------------------------------
alias vim='nvim'
alias ls="eza"
alias cat="bat"

# Editors and languages
# -------------------------------------------------------------------
alias pubkey="more ~/.ssh/id_ed25519.pub | pbcopy | echo '=> Public key copied to pasteboard.'"
alias cb='xclip -i -selection clipboard'

# System management
# -------------------------------------------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias findd="find . -type d -iname" # find a directory
alias findf="find . -type f -iname" # find a file 
alias fuck='sudo $(fc -ln -1)' # Redo last command with sudo

alias flushdns='sudo dscacheutil -flushcache; sudo killall - HUP mDNSResponder'
alias network='networkQuality'

#Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# FZF
source <(fzf --zsh)

# Prompt
eval "$(starship init zsh)"

