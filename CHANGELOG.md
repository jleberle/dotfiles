# Changelog

All notable changes to this dotfiles repo. Grouped by milestone rather than
individual commit — the git log has the full detail.

---

## 2026-05-31 — Improvements & forward compatibility

### Added
- `ltt` alias: `eza --tree --level=3` (one deeper than `lt`)
- `disk` alias: `df -h`
- `usage` alias: `du -sh -- *` (pairs with `biggest`)
- Git abbreviations: `gpl` (pull), `gf` (fetch), `gds` (diff --staged), `grst` (restore)
- `newdoc` fish function: bootstrap a Markdown file with Pandoc metadata template
- `make doctor` target: verify all expected symlinks are in place
- Forgejo Actions CI workflow (`.forgejo/workflows/lint.yml`): shellcheck, fish
  syntax, luacheck
- Go support: `gopls` in Brewfile, wired into `lsp.lua` and treesitter

### Changed
- `vim.loop` → `vim.uv` in `lazy.lua` (deprecation fix for Neovim 0.11+)
- Hardcoded `/opt/homebrew` paths in `config.fish` replaced with
  `$HOMEBREW_PREFIX` (set by `brew shellenv`); works on Apple Silicon, Intel,
  and Linux
- `env.fish` Homebrew bootstrap extended to cover Intel (`/usr/local`) and
  Linux (`/home/linuxbrew`) prefixes
- `homebrewupdate.sh` resolves the `brew` prefix at runtime rather than
  hardcoding `/opt/homebrew`; `brew cleanup` added to match the `brewup` alias
- `gpg.conf`: removed deprecated `keyid-format 0xlong`; `with-fingerprint`
  alone is sufficient and future-proof
- tmux terminal config consolidated from dual `terminal-overrides` entries into
  a single `terminal-features` declaration (tmux 3.2+); `prefix + z` zoom
  binding added
- Git aliases in `aliases.fish` converted from `alias` to `abbr` so expansions
  are visible in the buffer before pressing Enter
- `acp` function: guard against committing when nothing is staged
- `ipic` script: exit with a helpful message when search returns no results
- README updated to reflect all of the above

---

## 2026-05-29–30 — Full rewrite: zsh → fish, unified theme

The repo was significantly restructured. Everything zsh-related was removed and
replaced with a from-scratch fish configuration.

### Added
- Fish shell config (`fish/`): `config.fish`, `conf.d/` (env, options, aliases),
  `functions/` (acp, bb, cdf, fn, fuck, mkd, o, pman, wordfrequency)
- Starship prompt (`fish/starship.toml`): minimal directory/git/character format
  in Catppuccin Mocha colors
- fzf, zoxide, and starship initializations cached to disk; cache invalidated
  automatically when the binary is newer than the cache file
- Neovim rewritten from scratch: `lazy.nvim`, Catppuccin Mocha, Telescope,
  nvim-treesitter (main branch), nvim-cmp, nvim-lspconfig (`lua_ls`, `pyright`,
  `bashls`), conform.nvim, nvim-lint (vale), render-markdown, zen-mode, twilight,
  mini.nvim, oil.nvim, gitsigns, lualine
- Pandoc export keymaps (`<leader>ph` HTML, `<leader>pp` PDF) with automatic
  `metadata.yaml` detection and `pandoc-crossref` + `--citeproc` pipeline
- Vale prose linting wired into nvim-lint; `make vale` installs global config
- `templates/`: `metadata.yaml` (Pandoc metadata block), `vale.ini` (per-project
  config), Chicago Notes-Bibliography 17th edition CSL file
- Ghostty terminal config (`ghostty/config`): Catppuccin Mocha, JetBrainsMono
  Nerd Font, `macos-option-as-alt` for tmux `M-h`/`M-l`
- tmux config (`general/tmux.conf`): `C-a` prefix, vim pane navigation, TPM,
  Catppuccin Mocha status line, clipboard integration via `pbcopy`
- SSH hardening: curve25519/chacha20 only, `ControlMaster` multiplexing,
  `IdentitiesOnly`, no agent/X11 forwarding, `codeberg` host shortcut
- Launchd agents for automated weekly Homebrew updates and monthly log rotation
  (`make brewauto`)
- Brewfile reorganized and fully annotated
- README rewritten with full setup guide, keybinding tables, and per-section docs

### Changed
- Signing switched from GPG back to SSH (`gpg.format = ssh`)
- All configs unified on Catppuccin Mocha (Ghostty, Neovim, tmux, bat, fzf)

### Removed
- All zsh config files (zshrc, zshenv, zprofile, aliases, functions, plugins)
- zsh4humans, Zim, Powerlevel10k
- Old Neovim config (LazyVim-based)

---

## 2026-04-06 — Homebrew automation

### Added
- `bin/homebrewupdate.sh`: timestamped `brew update` + `outdated` + `upgrade`
- `bin/homebrewlogclean.sh`: monthly log rotation (runs only on the first Monday)
- Launchd plist templates for both scripts; `make brewauto` installs them

---

## 2026-01-10 — LazyVim

### Changed
- Neovim config updated to LazyVim (later replaced in the May 2026 rewrite)

---

## 2025-10-02 — Homebrew

### Changed
- Brewfile: consolidate `brew bundle` into a single `make apps` command

---

## 2024-10-29 — Neovim theme

### Changed
- Neovim theme updates (Catppuccin variants)

---

## 2023-10-08 — exa → eza

### Changed
- Replaced `exa` with `eza` across aliases and Brewfile (`exa` is unmaintained)

---

## 2023-08-22 — Audio tooling

### Added
- Opus audio conversion script and alias

---

## 2023-08-19 — SSH & signing

### Changed
- SSH config updated; signing method changed to GPG
- Email updated in gitconfig

---

## 2022-09-25 — Maintenance

### Fixed
- Weather alias zip code handling

---

## 2022-03-10

### Changed
- Removed `mas` from automated updates (caused unintended App Store upgrades)

---

## 2021-11-24

### Added
- `network` alias for `networkQuality` (macOS Monterey speed test)

---

## 2021-08 — Shell tooling & tmux

### Added
- fzf integration (keybindings, history search, file picker)
- zoxide (`z` frecency navigation)
- tmux config: `C-a` prefix, vim navigation, window renumbering, clipboard sync
- BBEdit functions (`bb`)
- `fuck` function (re-run last command under sudo)
- GPG config files added to repo and Makefile

### Changed
- Git aliases moved to `gitconfig` (out of shell aliases)
- Various alias fixes and consolidations across multiple commits

---

## 2021-07-15 — Initial commit

### Added
- zsh config (zshrc, aliases, functions) — the original shell setup
- SSH config
- gitconfig with delta pager
- Makefile for symlink management
- `ipic` script (iTunes/App Store artwork gallery, credit: Dr. Drang)
- `waybackup` script (save URLs to the Internet Archive)
