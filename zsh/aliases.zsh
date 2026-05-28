# Aliases
# --------------------------------------------------------------------
alias v='nvim'
alias vim='nvim'
alias cat="bat"

# Eza
alias ll='eza -lh --git --icons --group-directories-first'
alias la='eza -lah --git --icons --group-directories-first'
alias lt='eza --tree --level=2 --icons'

# recent files first
alias recent='eza -lah --sort=modified'

# biggest files
alias biggest='eza -lah --sort=size --reverse'

alias grep='rg'

alias cp='cp -i'
alias mv='mv -i'
alias reload='exec zsh'         # reload shell after editing dotfiles
alias path='echo -e ${PATH//:/\\n}'

alias network='networkQuality'
alias myip='curl -s https://ifconfig.me; echo'
alias ports='lsof -iTCP -sTCP:LISTEN -n -P'

# Housekeeping 
# -------------------------------------------------------------------
alias cleands='find . -type f -name "*.DS_Store" -delete'
alias showfiles='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
alias brewup='brew update && brew upgrade && brew cleanup'
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

# Editors and languages
# -------------------------------------------------------------------
alias pubkey='pbcopy < ~/.ssh/id_ed25519.pub && echo "=> Public key copied to pasteboard."'
alias cb='pbcopy'        # pipe into clipboard:  echo hi | cb
alias cv='pbpaste'       # paste from clipboard

# System management
# -------------------------------------------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias findd='fd --type d'   # find a directory:  findd foo
alias findf='fd --type f'   # find a file:       findf foo

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
