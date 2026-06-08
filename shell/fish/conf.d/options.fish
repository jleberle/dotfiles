# ------------------------------------------------------------------------------
# Shell behavior  (maps zsh setopt / history settings to fish equivalents)
#
# Most of what zshrc configures by hand is a fish default. This file documents
# the mapping so the parity (and the gaps) are explicit.
# ------------------------------------------------------------------------------

# --- History ------------------------------------------------------------------
# zsh: HISTFILE / HISTSIZE=100000 / SHARE_HISTORY / HIST_IGNORE_DUPS /
#      HIST_REDUCE_BLANKS / HIST_EXPIRE_DUPS_FIRST / EXTENDED_HISTORY ...
# fish: history lives in ~/.local/share/fish/fish_history, is shared across
#       sessions live, de-duplicates, and is effectively unbounded — all by
#       default. There is nothing to set; the behavior is built in.
#   GAP: HIST_IGNORE_SPACE has no built-in fish equivalent (a leading space
#        does not exclude a command from history).

# --- Directory navigation -----------------------------------------------------
# zsh: AUTO_PUSHD / PUSHD_IGNORE_DUPS / PUSHD_MINUS
# fish: keeps a directory history automatically. Use `prevd`/`nextd`
#       (bound to Alt-Left / Alt-Right), `cd -` for the previous dir, and
#       `dirh` to list it. This covers the pushd workflow without setopts.
#   GAP: AUTO_CD (bare `foo` to cd into ./foo) is intentionally absent in fish.
#        Use `cd foo`; zoxide's `z` also covers most of the convenience.

# --- Globbing -----------------------------------------------------------------
# zsh: EXTENDED_GLOB
# fish: recursive `**` globbing and rich expansion are built in; a non-matching
#       glob is an error in command position but expands to nothing in `set`,
#       `for`, and `count` (relied on by the `fn` function).

# --- Misc ---------------------------------------------------------------------
# INTERACTIVE_COMMENTS  -> fish supports `#` comments interactively by default.
# NO_CLOBBER            -> fish has NO equivalent: `>` overwrites. Use `>>` to
#                          append; there is no global clobber guard.

# Disable the default fish greeting for a clean prompt (zsh had none).
set -g fish_greeting
