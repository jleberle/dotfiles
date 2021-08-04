# Editors and languages
# -------------------------------------------------------------------
alias vim='nvim'
alias R="R --no-save --no-restore-data --quiet"
alias pubkey="more ~/.ssh/id_ed25519.pub | pbcopy | echo '=> Public key copied to pasteboard.'"

# System management
# -------------------------------------------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias findd="find . -type d -iname" # find a directory
alias findf="find . -type f -iname" # find a file 
alias more='more -R'                # give more colors
alias c='clear'

alias ip="curl icanhazip.com"       # get current public IP
alias checkup="ping -c3 google.com"
alias flushdns='sudo dscacheutil -flushcache; sudo killall - HUP mDNSResponder'

alias brewup='brew update && brew upgrade && brew cleanup'
alias brewcheck='brew outdated && brew autoremove && brew cleanup && brew doctor'
alias adg="sudo apt update && sudo apt upgrade"
alias adc="sudo apt autoremove && sudo apt purge"

alias rprofile="source ~/.zshrc"
alias eprofile="nvim ~/.zshrc"
alias ealias="vim ~/.dotfiles/zsh/aliases.zsh"

if $(gls &>/dev/null)
then
  alias ls="gls -F --color"
  alias l="gls -lAh --color"
  alias ll="gls -l --color"
  alias la='gls -A --color'
else
  alias ls="ls -F --color"
  alias l="ls -lAh --color"
  alias ll="la -l --color"
  alias la="ls -A --color"
fi

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
