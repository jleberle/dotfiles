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

# Functions
# -----------------------------------------------------------------------
function wordfrequency() {
  awk '
     BEGIN { FS="[^a-zA-Z]+" } {
         for (i=1; i<=NF; i++) {
             word = tolower($i)
             words[word]++
         }
     }
     END {
         for (w in words)
              printf("%3d %s\n", words[w], w)
     } ' | sort -rn
}

# Open man man pages in Preview
function pman() { man -t "$@" | open -f -a "Preview" ;}

# Functions
# (f)ind by (n)ame
# usage: fn foo 
# to find all files containing 'foo' in the name
function fn() { ls **/*$1* }

# `o` with no arguments opens the current directory, otherwise opens the given
# location
function o() {
	if [ $# -eq 0 ]; then
		open .;
	else
		open "$@";
	fi;
}

# Create a new directory and enter it
function mkd() {
	mkdir -p "$@" && cd "$_";
}

# Change working directory to the top-most Finder window location
function cdf() { # short for `cdfinder`
	cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')";
}

function acp() {
  git add .
  git commit -S -m "$1"
  git push
}

#
# If the bb command is called without an argument, launch BBEdit
# If bb is passed a directory, cd to it and open it in BBEdit
# If bb is passed a file, open it in BBEdit
#
function bb() {
    if [[ -z "$1" ]]
    then
        bbedit --launch
    else
        bbedit "$1"
        if [[ -d "$1" ]]
        then
            cd "$1"
        fi
    fi
}
