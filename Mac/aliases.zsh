# Directories
# -------------------------------------------------------------------
alias projects='cd ~/Dropbox/Projects'
alias website='cd ~/Website'

# System management
# -------------------------------------------------------------------
alias findd="find . -type d -iname" # find a directory
alias findf="find . -type f -iname" # find a file 
alias ip="curl icanhazip.com"       # get current public IP
alias more='more -R'                # give more colors
alias files='du -hd 1 . | sort -hr' # https://leancrew.com/all-this/2020/05/sort-of-handy/
alias dircolors='gdircolors'

# Editing zshrc/vim profiles
alias vim='nvim'

alias eprofile="$EDITOR ~/Dropbox/Dotfiles/Mac/zshrc.zsh"
alias rprofile="source ~/.zshrc"

# Git 
# -------------------------------------------------------------------
alias gs='git status -sb'
alias gsa="find . -maxdepth 1 -mindepth 1 -type d -exec sh -c '(echo {} && cd {} && git status -s && echo)' \;" # Git status for all repos in a folder

# Program Aliases
# -------------------------------------------------------------------
alias mp3='cd ~/Music && youtube-dl -x --audio-format mp3'
alias video='cd ~/Movies && youtube-dl -f bestvideo+bestaudio'
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

# Zippin
alias gz='tar -zcvf'

# Use zmv, which is amazing
autoload -U zmv
alias zmv="noglob zmv -W"

# Functions
# -------------------------------------------------------------------

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
