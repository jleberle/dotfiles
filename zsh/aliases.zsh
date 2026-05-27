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
alias fuck='sudo $(fc -ln -1)' # Redo last command with sudo

alias rmi='rm -riv' # Prompt for removal, recursive and print results
alias mvi='mv -iv' # Prompt for move and print result
alias mkdir='mkdir -vp' # Make dir and subdirs and print results

alias ip="curl icanhazip.com"       # get current public IP
alias checkup="ping -c3 google.com"
alias flushdns='sudo dscacheutil -flushcache; sudo killall - HUP mDNSResponder'
alias network='networkQuality'
