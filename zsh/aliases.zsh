# Aliases
# --------------------------------------------------------------------
alias v='nvim'
alias vim='nvim'
alias cat="bat"

alias ls='eza --icons'
alias ll='eza -lah --icons'
alias lt='eza --tree --level=2 --icons'
alias tree='eza --tree --icons'
alias grep='rg'

# Editors and languages
# -------------------------------------------------------------------
alias pubkey="more ~/.ssh/id_ed25519.pub | pbcopy | echo '=> Public key copied to pasteboard.'"

alias cb='pbcopy'        # pipe into clipboard:  echo hi | cb
alias cv='pbpaste'       # paste from clipboard

# System management
# -------------------------------------------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias findd="find . -type d -iname" # find a directory
alias findf="find . -type f -iname" # find a file 
alias fuck='sudo $(fc -ln -1)' # Redo last command with sudo

alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
alias network='networkQuality'

# Git
# ---------------------------------------------------------------------
alias lg='lazygit'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit -S'        # matches your signed-commit convention in `acp`
alias gp='git push'
alias gd='git diff'             # delta picks this up via your gitconfig
alias gl='git log --oneline --graph --decorate -20'
alias gco='git checkout'
alias gb='git branch'
