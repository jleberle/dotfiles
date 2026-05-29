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
    # `init` output of fzf/zoxide/starship, rebuilt only when the tool updates.
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
    # Catppuccin Mocha palette (matches ghostty, nvim, bat, tmux)
    set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 --color=border:#6c7086"

    # Cache `fzf --fish` output; rebuild if the fzf binary is newer than cache.
    set -l fzf_cache $cache/fzf.fish
    set -l fzf_bin /opt/homebrew/bin/fzf
    if not test -s $fzf_cache; or test $fzf_bin -nt $fzf_cache
        $fzf_bin --fish >$fzf_cache
    end
    source $fzf_cache

    # --------------------------------------------------------------------------
    # Zoxide
    # --------------------------------------------------------------------------
    set -l zoxide_cache $cache/zoxide.fish
    set -l zoxide_bin /opt/homebrew/bin/zoxide
    if not test -s $zoxide_cache; or test $zoxide_bin -nt $zoxide_cache
        $zoxide_bin init fish >$zoxide_cache
    end
    source $zoxide_cache

    # --------------------------------------------------------------------------
    # Prompt (starship — config at fish/starship.toml -> ~/.config/starship.toml)
    # --------------------------------------------------------------------------
    set -l starship_cache $cache/starship.fish
    set -l starship_bin /opt/homebrew/bin/starship
    if not test -s $starship_cache; or test $starship_bin -nt $starship_cache
        $starship_bin init fish >$starship_cache
    end
    source $starship_cache
end
