# ------------------------------------------------------------------------------
# Aliases  (mirrors zsh/aliases.zsh)
#
# In fish, `alias` defines a thin wrapper function (any extra arguments are
# appended). For abbreviations that expand inline as you type, use `abbr`.
# ------------------------------------------------------------------------------

alias v 'nvim'
alias vim 'nvim'
alias cat 'bat'

# Eza
alias ls 'eza --icons'
alias ll 'eza -lh --git --icons --group-directories-first'
alias la 'eza -lah --git --icons --group-directories-first'
alias lt 'eza --tree --level=2 --icons'

# recent files first
alias recent 'eza -lah --sort=modified'

# biggest files
alias biggest 'eza -lah --sort=size --reverse'

alias cp 'cp -i'
alias mv 'mv -i'
alias reload 'exec fish'        # reload shell after editing dotfiles
# NB: not `path` — that's a fish builtin (`path filter`/`basename`/…); shadowing
# it breaks completions (e.g. git's) that call the builtin.
alias paths 'string join \n $PATH'

alias myip 'curl -s https://ifconfig.me; echo'
alias ports 'lsof -iTCP -sTCP:LISTEN -n -P'

# Housekeeping
alias cleands 'find . -type f -name "*.DS_Store" -delete'
alias brewup 'brew update && brew upgrade && brew upgrade --cask && brew cleanup'

# macOS-only aliases
if test (uname) = Darwin
    alias network 'networkQuality'
    alias showfiles 'defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
    alias hidefiles 'defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
    alias flushdns 'sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
    alias pubkey 'pbcopy < ~/.ssh/id_ed25519.pub && echo "=> Public key copied to pasteboard."'
    alias cb 'pbcopy'        # pipe into clipboard:  echo hi | cb
    alias cv 'pbpaste'       # paste from clipboard
end

# System management
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'
alias findd 'fd --type d'   # find a directory:  findd foo
alias findf 'fd --type f'   # find a file:       findf foo

# Eza extras
alias ltt 'eza --tree --level=3 --icons'   # one level deeper than lt

# System monitoring
alias disk  'df -h'                         # free/used space per mount
alias usage 'du -sh -- *'                   # directory sizes in cwd (pairs with biggest)

# Git — abbreviations expand inline before Enter so you can see what runs.
# `abbr` is fish-native; aliases would hide the expansion.
abbr -a lg  lazygit
abbr -a gs  'git status -sb'
abbr -a ga  'git add'
abbr -a gc  'git commit -S'
abbr -a gp  'git push'
abbr -a gpl 'git pull'
abbr -a gf  'git fetch'
abbr -a gd  'git diff'
abbr -a gds 'git diff --staged'
abbr -a gl  'git log --oneline --graph --decorate -20'
abbr -a gco 'git checkout'
abbr -a gb  'git branch'
abbr -a grst 'git restore'

# Website theme submodule update
alias update-theme 'git -C /Users/jaredeberle/git/website submodule update --remote themes/PaperMod'
