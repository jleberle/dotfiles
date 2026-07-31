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
set -gx HOMEBREW_NO_ENV_HINTS 1       # suppress hints in brew output
set -gx HOMEBREW_NO_ANALYTICS 1       # disable telemetry
set -gx HOMEBREW_NO_INSECURE_REDIRECT 1  # refuse http→https / cross-host download redirects
if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv fish | source
end

# --- PATH ---------------------------------------------------------------------
# zprofile prepended ~/git/dotfiles/bin and ~/.local/bin ahead of everything.
# fish_add_path is idempotent and de-duplicates (the `typeset -U path` analog).
# --global keeps this per-session (recomputed each startup) instead of writing
# to universal variables, so nothing leaks into the repo's fish_variables.
fish_add_path --global --prepend $HOME/git/dotfiles/bin $HOME/.local/bin

# --- GPG ----------------------------------------------------------------------
# Required for pinentry to open a passphrase prompt in the current terminal.
# Guarded: in non-interactive shells `tty` returns the literal "not a tty",
# which would leak a garbage value to any gpg invocation.
if test -t 0
    set -gx GPG_TTY (tty)
end

# --- SSH agent (Secretive) ----------------------------------------------------
# Route ssh-agent to Secretive's Secure Enclave socket when it exists, so ssh,
# git, AND ssh-keygen all use the enclave keys (ssh-keygen ignores ssh_config's
# IdentityAgent and only honors SSH_AUTH_SOCK — needed for e.g. Codeberg/Forgejo
# `ssh-keygen -Y sign` key verification and commit signing). Guarded on the
# socket so a machine without Secretive falls back to the default agent.
set -l secretive_sock $HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
if test -S $secretive_sock
    set -gx SSH_AUTH_SOCK $secretive_sock
end

# --- umask --------------------------------------------------------------------
# Default to owner-only permissions (0600 files / 0700 dirs) for anything created
# without an explicit mode. Defense-in-depth on a single-user Mac. NOTE: this
# applies to every fish session, scripts included — if a workflow needs group/
# other read (e.g. files served by a local web root), chmod those explicitly.
umask 077

# --- Editors / pagers (mirrors zshenv) ----------------------------------------
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PAGER 'bat --style=plain'
set -gx MANPAGER 'nvim +Man!'

# Keep ANSI colors when paging (e.g. piped --help, colored output)
set -gx LESS -R

# Match bat's syntax theme to the Nord terminal theme
set -gx BAT_THEME 'Nord'

# --- LS_COLORS ----------------------------------------------------------------
# Consumed by eza (and any GNU ls). Prefer GNU dircolors; fall back to a sane
# default. (fish's own completion-menu colors are themed separately, via the
# fish_color_* / fish_pager_color_* variables — see conf.d/options.fish.)
if type -q dircolors
    set -gx LS_COLORS (dircolors -b | string match -rg "LS_COLORS='(.*)';")
else
    set -gx LS_COLORS 'di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=34;42'
end
