# Directories
# -------------------------------------------------------------------
alias projects='cd ~/Git/Projects'
alias wiki='cd ~/Git/notebook'
alias cv='cd ~/Git/CV'
alias bib='cd ~/Git/Bib'
alias diss='cd ~/Documents/Dissertation'

# System management
# -------------------------------------------------------------------
alias findd="find . -type d -iname" # find a directory
alias findf="find . -type f -iname" # find a file 
alias ip="curl icanhazip.com"       # get current public IP
alias more='more -R'                # give more colors
alias files='du -hd 1 . | sort -hr' # https://leancrew.com/all-this/2020/05/sort-of-handy/

alias ls='gls --color=auto'  
alias ll='ls -al'

# Editing zshrc/vim profiles
alias vim='nvim'

alias eprofile="$EDITOR ~/Git/dotfiles/zsh/zshrc.zsh"
alias rprofile="source ~/.zshrc"

# Git 
# -------------------------------------------------------------------
alias ga='git add'
alias gc='git commit'
alias gca='git commit -a'
alias gcam='git commit -a -m'
alias gcm='git commit -m'
alias glog="git log --graph --pretty=format:'%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
alias gs='git status -sb'
alias gl='git pull --ff-only'
alias gp='git push'
alias gsa="find . -maxdepth 1 -mindepth 1 -type d -exec sh -c '(echo {} && cd {} && git status -s && echo)' \;" # Git status for all repos in a folder

# Program Aliases
# -------------------------------------------------------------------
alias mp3='cd ~/Music && youtube-dl -x --audio-format mp3'
alias video='cd ~/Movies && youtube-dl -f bestvideo+bestaudio'
alias flushdns='sudo killall -HUP mDNSResponder'

# Zippin
alias gz='tar -zcvf'

#mplayer 
alias wfmu='mplayer -nocache -playlist http://www.wfmu.org/wfmu_aac.pls'
alias xpn='mplayer -nocache http://xpohi.streamguys.net:80/xpohi'
alias kexp='mplayer -nocache -afm ffmpeg http://kexp-mp3-128.streamguys1.com/kexp128.mp3'
alias thespy='mplayer -nocache http://16113.live.streamtheworld.com:3690/KOSUHD2_SC'
alias yacht='mplayer -playlist http://somafm.com/seventies130.pls'
alias folk='mplayer -playlist http://somafm.com/folkfwd130.pls'
alias alt='mplayer -playlist http://somafm.com/bagel130.pls'
alias country='mplayer -playlist http://somafm.com/bootliquor130.pls'
alias focus='mplayer -playlist http://somafm.com/deepspaceone130.pls'
alias celtic='mplayer -playlist http://somafm.com/thistle130.pls'
alias jazz='mplayer -playlist http://somafm.com/sonicuniverse130.pls'
alias scanner='mpv https://www.broadcastify.com/scripts/playlists/1/31184/-6349349068.m3u'

# Use zmv, which is amazing
autoload -U zmv
alias zmv="noglob zmv -W"

## Homebrew
## -------------------------------------------------------------------
# Check for updates
whatsnew() {
  echo "Checking homebrew packages..."
  brew update > /dev/null;
  new_packages=$(brew outdated --quiet)
  num_packages=$(echo $new_packages | wc -w)

  if [ $num_packages -gt 0 ]; then
    echo "New package updates available:"
    for package in $new_packages; do 
      echo "  * $package";
    done
  else
    echo "No new package updates available."
  fi
}

alias autobrew='brew upgrade; brew cleanup; brew doctor'

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

