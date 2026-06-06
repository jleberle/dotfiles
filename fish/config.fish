# ==============================================================================
# config.fish  (mirrors the interactive half of zsh/zshrc)
#
# Sourcing order in fish:
#   1. conf.d/*.fish   -> env.fish, options.fish, aliases.fish  (always)
#   2. config.fish     -> this file                              (always)
# Interactive-only setup is guarded so non-interactive shells stay fast.
#
# Native to fish, so deliberately NOT configured here:
#   * autosuggestions      (replaces zsh-autosuggestions)
#   * syntax highlighting   (replaces zsh-syntax-highlighting)
#   * completions           (replaces compinit + zstyle; no setup needed)
#   * up-arrow prefix history search (the zsh up-line-or-beginning-search bind)
# ==============================================================================

if status is-interactive
    # XDG-style cache location (mirrors ZSH_CACHE_DIR). Used to cache the
    # `init` output of fzf/zoxide, rebuilt only when the tool updates.
    set -l cache $HOME/.cache/fish
    test -d $cache; or mkdir -p $cache

    # --------------------------------------------------------------------------
    # Keybindings
    # --------------------------------------------------------------------------
    # fish defaults to emacs-style bindings and up/down already do a prefix
    # history search, so only the Ctrl-Left/Right word motions need binding.
    bind ctrl-right forward-word
    bind ctrl-left  backward-word

    # --------------------------------------------------------------------------
    # FZF
    # --------------------------------------------------------------------------
    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
    set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'
    set -gx FZF_ALT_C_OPTS "--preview 'eza --tree --level=2 --icons --color=always {}'"
    # Nord palette (matches ghostty, nvim, bat, tmux)
    set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border --color=bg+:#3B4252,bg:#2E3440,spinner:#81A1C1,hl:#616E88 --color=fg:#D8DEE9,header:#616E88,info:#81A1C1,pointer:#81A1C1 --color=marker:#81A1C1,fg+:#D8DEE9,prompt:#81A1C1,hl+:#81A1C1 --color=border:#4C566A"

    # Cache `fzf --fish` output; rebuild if the fzf binary is newer than cache.
    # Uses $HOMEBREW_PREFIX (set by `brew shellenv` in conf.d/env.fish) so this
    # works on Apple Silicon (/opt/homebrew), Intel (/usr/local), and Linux.
    set -l fzf_cache $cache/fzf.fish
    set -l fzf_bin $HOMEBREW_PREFIX/bin/fzf
    if not test -s $fzf_cache; or test $fzf_bin -nt $fzf_cache
        $fzf_bin --fish >$fzf_cache
    end
    source $fzf_cache

    # --------------------------------------------------------------------------
    # Zoxide
    # --------------------------------------------------------------------------
    set -l zoxide_cache $cache/zoxide.fish
    set -l zoxide_bin $HOMEBREW_PREFIX/bin/zoxide
    if not test -s $zoxide_cache; or test $zoxide_bin -nt $zoxide_cache
        $zoxide_bin init fish >$zoxide_cache
    end
    source $zoxide_cache

    # Prompt is handled by fish/functions/fish_prompt.fish (native fish, no external dependency)
end
