# Editors and languages
# -------------------------------------------------------------------
alias vim='nvim'
alias pubkey="more ~/.ssh/id_ed25519.pub | pbcopy | echo '=> Public key copied to pasteboard.'"
alias cb='xclip -i -selection clipboard'
alias bbpb='pbpaste | bbedit --clean --view-top'
alias bbd=bbdiff

# System management
# -------------------------------------------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias findd="find . -type d -iname" # find a directory
alias findf="find . -type f -iname" # find a file 
alias c='clear'
alias fuck='sudo $(fc -ln -1)' # Redo last command with sudo

alias ls='exa -l --color=auto --group-directories-first'
alias la='exa -la --color=auto --group-directories-first'

alias rmi='rm -riv' # Prompt for removal, recursive and print results
alias mvi='mv -iv' # Prompt for move and print result
alias mkdir='mkdir -vp' # Make dir and subdirs and print results

alias ip="curl icanhazip.com"       # get current public IP
alias checkup="ping -c3 google.com"
alias flushdns='sudo dscacheutil -flushcache; sudo killall - HUP mDNSResponder'

# Git
# ------------------------------------------------------------------
alias ga='git add'
alias gc='git commit'
alias gca='git commit -a'
alias gcam='git commit -a -m'
alias gcm='git commit -m'
alias glog="git log --graph --pretty=format:'%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
alias gs='git status -sb'
alias gl='git pull --ff-only'

# Updates
# ------------------------------------------------------------------
alias brewup='brew update && brew upgrade && brew cleanup'
alias brewcheck='brew outdated && brew autoremove && brew cleanup && brew doctor'
alias adg="sudo apt update && sudo apt upgrade"
alias adc="sudo apt autoremove && sudo apt purge"

alias reload="exec zsh"
alias eprofile="nvim ~/.zshrc"
alias ealias="vim ~/.dotfiles/zsh/aliases.zsh"

# Fun Stuff
# -----------------------------------------------------------------------

alias wttr='curl wttr.in/74075'
alias ctwttr='curl wttr.in/06082'

alias ytd='noglob youtube-dl --ignore-errors --continue --no-overwrites --format 'bestvideo+bestaudio' --output "~/Videos/%(title)s.%(ext)s" "$@"'
