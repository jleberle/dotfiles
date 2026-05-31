# ------------------------------------------------------------------------------
# Environment + PATH  (mirrors zsh/zshenv + zsh/zprofile)
#
# conf.d/*.fish is sourced for EVERY fish session (interactive, login, and
# script), so this is the fish equivalent of zshenv/zprofile: things that must
# exist regardless of how the shell was started.
# ------------------------------------------------------------------------------

# --- Homebrew -----------------------------------------------------------------
# Equivalent to `eval "$(brew shellenv)"` in zprofile. The `fish` argument makes
# brew emit fish syntax (set -gx / fish_add_path) instead of POSIX exports.
# Checks known prefixes in order: Apple Silicon, Intel Mac, Linux.
if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv fish | source
else if test -x /usr/local/bin/brew
    /usr/local/bin/brew shellenv fish | source
else if test -x /home/linuxbrew/.linuxbrew/bin/brew
    /home/linuxbrew/.linuxbrew/bin/brew shellenv fish | source
end

# --- PATH ---------------------------------------------------------------------
# zprofile prepended ~/.dotfiles/bin and ~/.local/bin ahead of everything.
# fish_add_path is idempotent and de-duplicates (the `typeset -U path` analog).
# --global keeps this per-session (recomputed each startup) instead of writing
# to universal variables, so nothing leaks into the repo's fish_variables.
fish_add_path --global --prepend $HOME/.dotfiles/bin $HOME/.local/bin

# --- Editors / pagers (mirrors zshenv) ----------------------------------------
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PAGER less
set -gx MANPAGER 'nvim +Man!'

# Keep ANSI colors when paging (e.g. piped --help, colored output)
set -gx LESS -R

# Match bat's syntax theme to the Catppuccin Mocha terminal theme
set -gx BAT_THEME 'Catppuccin Mocha'

# --- LS_COLORS ----------------------------------------------------------------
# Consumed by eza (and any GNU ls). Prefer GNU dircolors; fall back to a sane
# default. (fish's own completion-menu colors are themed separately, via the
# fish_color_* / fish_pager_color_* variables — see conf.d/options.fish.)
if type -q dircolors
    set -gx LS_COLORS (dircolors -b | string match -rg "LS_COLORS='(.*)';")
else
    set -gx LS_COLORS 'di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=34;42'
end
