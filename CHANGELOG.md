# Changelog

All notable changes to this dotfiles repo. Grouped by milestone rather than
individual commit — the git log has the full detail.

---

## 2026-06-08 — NeoMutt integration (refined)

### Changed
- `colors.rc` — fixed incorrect Nord ANSI palette mapping (color1=Aurora red,
  not Polar Night); indicator is now Snow Storm on Polar Night 3 (readable);
  status bar is Frost cyan on Polar Night 1
- `mutt` alias moved from a standalone function file to `conf.d/aliases.fish`
  alongside `alias vim 'nvim'` where it belongs
- `mailcap` — HTML emails now render inline via macOS `textutil` (`auto_view`);
  press `\Ch` to open in Firefox instead
- `neomuttrc` — added `auto_view text/html`, `alternative_order` (prefer plain
  text), clean `status_format`/`pager_format` with left/right layout, removed
  spurious `[RO]` flag, rebound `sidebar-open` from `Ctrl-O` to `B`
- `accounts/example.rc` — updated to document Apple Mail Keychain conflict
  (Apple Mail stores iCloud OAuth tokens under the same server keys, causing
  `security find-internet-password` to return a hex token); direct password
  with `chmod 600` documented as the reliable approach; `%40` encoding for `@`
  in `smtp_url`; iCloud-specific settings added

## 2026-06-08 — NeoMutt integration

### Added
- `writing/neomutt/` — NeoMutt configuration:
  - `neomuttrc` — core config: threading, vim-style keybindings, sidebar,
    index/pager layout, nvim as editor
  - `gpg.rc` — GPGME-backed PGP using the same key as `make security`;
    auto-encrypt/sign replies, verify all incoming signatures
  - `colors.rc` — dark color scheme matching the Ghostty/nvim aesthetic
  - `mailcap` — content handlers (HTML→Firefox, PDFs/images via macOS `open`)
  - `accounts/example.rc` — account template using macOS Keychain for passwords
- `make neomutt` — symlinks config files into `~/.config/neomutt/`, creates
  cache dirs, stubs `accounts/local.rc` on first run with a reminder
- `neomutt` added to `make install` dependency chain
- `make doctor` check for neomuttrc symlink
- `mutt` alias for `neomutt` in `conf.d/aliases.fish`
- `neomutt` added to `homebrew/Brewfile` (alphabetical order)
- README: NeoMutt subsection under Apps; Makefile Options table updated;
  Quick Start per-app table updated

---

## 2026-06-08 — Prepend brew update logs; README/Makefile doc update

### Changed
- `bin/homebrewupdate.sh`: captures all output to a temp file and prepends it
  to `~/.local/brew_update_logs.txt` so the newest run always appears at the
  top of the file instead of at the bottom
- `homebrew/org.jaredeberle.brewupdate.plist`: removed `StandardOutPath` and
  `StandardErrorPath` — the script now owns its own logging
- README Scripting → Launchd and `make brewauto` message updated to reflect
  newest-run-first ordering

---

## 2026-06-08 — README reorganization, check system, stale artifact cleanup

### Added
- `make clean`: removes stale `fish/` and `general/` directories left over
  from the 2026-06-08 repo restructure on machines that had the repo checked
  out beforehand — git pull does not remove untracked/gitignored directories
- `make dots` fish function: run any dotfiles make target from any directory
- README reorganized into: Quick Start → Check System → Makefile Options →
  Apps (Ghostty, Fish, Neovim, tmux, Git) → Prose and Pandoc →
  Scripting (Bin, Launchd) → Security → Repository Layout → Credits
- Check System is now a dedicated README section covering `doctor`,
  `macos-check`, `brew-check`, `tools-check`, and `clean`

### Fixed
- Quick Start numbered steps now include `make chsh` (was only in the
  per-app table, missing from the sequence)
- Makefile Options `vale` row now mentions `vale sync`
- Prose and Pandoc section: corrected stale claim that "No `vale sync` is
  needed" and "built-in Vale style only" — the config lists four external
  packages and `make vale` always runs `vale sync`
- Security section: `gpg-agent.conf` corrected to `gpg-agent.conf.tmpl`
- `.gitignore`: removed stale `general/gpg-agent.conf` entry (path no longer
  exists after `general/` was renamed to `security/`)

---

## 2026-06-08 — New machine automation, Betterfox submodule, macOS defaults

### Added
- `make macos`: writes sensible macOS system defaults — keyboard repeat
  (`ApplePressAndHoldEnabled`, `KeyRepeat 2`, `InitialKeyRepeat 15`), Finder
  (extensions, path bar, status bar, folder sort, current-folder search, no
  extension-change warning, no `.DS_Store` on network/USB), Dock (autohide, no
  recent apps, minimize-to-app), screenshots (saved to `~/Desktop/Screenshots`,
  no shadow), and system (expanded save/print panels, save to disk not iCloud,
  no smart quotes/dashes, immediate screensaver password); restarts Finder, Dock,
  and SystemUIServer to apply immediately
- `make latex`: installs the `tlmgr` packages required for PDF export via BasicTeX;
  guards against running when `tlmgr` is not found
- `make chsh`: adds fish to `/etc/shells` and sets it as the login shell via `dscl`
  (idempotent; requires sudo)
- `make install`: updated post-run message to note `make firefox` and `make latex`
- Betterfox tracked as a git submodule at `security/betterfox/`; `make firefox` now
  concatenates `security/betterfox/user.js` + `security/user-overrides.js` into a
  single `user.js` written to the active Firefox profile (Firefox only reads `user.js`
  natively — `user-overrides.js` is never edited by upstream)
- `make betterfox-update`: pulls the latest Betterfox commit into the submodule
- `security/user-overrides.js`: personal Firefox prefs extracted from the old
  `security/user.js` — Smoothfox scroll tuning, DoH/NextDNS, shutdown sanitizing,
  service worker and JIT hardening, captive portal disable, built-in VPN disable

### Changed
- Quick start clone command updated to `--recurse-submodules` (required for Betterfox)
- `make apps`: Homebrew auto-install means the manual Homebrew install step is removed
  from the quick start
- README quick start updated to reflect full new-machine sequence:
  `apps → install → macos → chsh → firefox → latex`

### Removed
- `security/user.js`: replaced by Betterfox submodule + `user-overrides.js`

---

## 2026-06-08 — Repo restructure, bat and lazygit configs, Firefox user.js wiring

### Added
- `shell/bat/config`: Nord theme, `numbers,changes,header-filename` style, syntax
  mappings for `.fish`, `Brewfile`, and `.env*` files
- `git/lazygit.yml`: Nord theme, delta pager integration (`--paging=never`), nvim
  editor, NerdFonts v3 icons
- `make firefox`: detects the default Firefox profile via `installs.ini` (profile
  string varies per machine) and symlinks `security/user.js` into it; `make doctor`
  checks the symlink when Firefox has been launched

### Changed
- **Repo layout** reorganised into six top-level directories:
  - `fish/`, `ghostty/` → `shell/` (also absorbs `tmux.conf` from `general/` and new `bat/`)
  - `general/` → `security/` (SSH, GPG) + `writing/vale/` (Vale configs)
  - `templates/` → `writing/pandoc/` (Pandoc templates, CSL, reference.docx)
  - `nvim/` → `writing/nvim/`
  - `launchd/` → `homebrew/` (alongside Brewfile)
  - `lazygit/config.yml` → `git/lazygit.yml` (flattened into `git/`)
  - `templates/user.js` → `security/user.js`
- **Makefile** targets reduced from 12 → 9:
  - `git` absorbs lazygit symlinking
  - `shell` replaces `fish`, `ghostty`, `tmux` (adds `bat`)
  - `auth` renamed to `security`
  - `firefox` added (new)
  - Individual `ghostty`, `tmux`, `fish` targets removed
- `make security`: `gpg-agent.conf` now written directly to `~/.gnupg/gpg-agent.conf`
  via `sed` substitution (same pattern as `make vale`) — no intermediate generated
  file in the repo, no symlink for that file
- `writing/vale/vale.ini`: fixed stale comment that said `vale sync` was not required
  (it is — four external packages are listed)
- `security/gpg-agent.conf.tmpl`: updated comment to reference `make security` and
  correct destination path

---

## 2026-06-06 — GPG hardening, bat pager, Tor Browser, starship.toml removal

### Added
- `general/common.conf` tracked in dotfiles (`use-keyboxd`); `make auth` symlinks it to `~/.gnupg/common.conf`; `make doctor` checks the symlink
- `gpg.conf`: `import-options import-minimal` and `export-options export-minimal` — strip subkeys/sigs on import/export
- `gpg-agent.conf`: `no-allow-loopback-pinentry` — require physical pinentry, block programmatic passphrase injection
- Tor Browser added to Brewfile

### Changed
- `PAGER` switched from `less` to `bat --style=plain` in `env.fish` — syntax-highlighted paging with clean output
- `dirmngr.conf`: replaced `disable-ipv6` with `disable-ldap` — disables legacy LDAP protocol instead of IPv6

### Removed
- `gpg.conf`: removed deprecated `use-agent` and `sig-keyserver-url` directives
- `fish/starship.toml` — file deleted; Starship is fully gone from the repo (already removed from config.fish and Makefile in earlier commits)

---

## 2026-06-06 — Brewfile cleanup, Homebrew privacy, mole

### Added
- `mole` to Brewfile — deep clean and optimize macOS
- `HOMEBREW_NO_ENV_HINTS` and `HOMEBREW_NO_ANALYTICS` to `env.fish` — suppress
  hints and disable Homebrew telemetry

### Removed
- `ffmpeg`, `exiftool`, `git-lfs`, `gibo`, `ocrmypdf`, `wget`, `rbenv`, `pipx`,
  `r-app`, `pyenv`, `gh`, `grc`, `spark`, `starship` from Brewfile — none
  actively used in dotfiles or any project
- Improved Brewfile comments to note where each tool is used

---

## 2026-06-06 — Nord theme, native fish prompt, dependency cleanup

### Added
- Native `fish_prompt` function replacing Starship — identical output (directory,
  git branch/status, prompt character) with no external dependency
- `tmux` alias: `tmux new-session -A -s main` to avoid "no current session" error

### Changed
- Theme switched from Catppuccin Mocha to Nord across all tools: Ghostty, Neovim
  (`gbprod/nord.nvim`), lualine, tmux (`arcticicestudio/nord-tmux`), bat, delta, fzf
- Neovim: replaced `catppuccin/nvim` with `gbprod/nord.nvim` (actively maintained,
  full treesitter and LSP semantic token support)
- Tmux: replaced `catppuccin/tmux` with `arcticicestudio/nord-tmux`
- `ghostty/config`: `shell-integration` changed from `detect` to `fish`
- `fish_prompt`: `--dir-length 0` to show full directory names without abbreviation

### Removed
- Starship from Brewfile, `config.fish`, Makefile, and doctor target
- `grc` and `spark` from Brewfile — not referenced anywhere in the config

---

## 2026-06-06 — SSH hardening, GPG commit signing, key management

### Added
- SSH: dedicated key per host (`id_github`, `id_codeberg`) with explicit `IdentityFile` in each `Host` block
- SSH: `github-443` fallback host alias (`ssh.github.com:443`) for networks that block port 22
- `gpg-master-import` fish function: imports offline master key from USB with mount check
- `gpg-master-done` fish function: exports machine-specific subkeys, wipes keyring, reimports correctly; detects machine via `scutil --get LocalHostName` (Leia/Ahsoka)
- `env.fish`: `GPG_TTY` set to fix pinentry prompts in terminal
- Git abbreviations: `glo` (full graph log), `gund` (undo), `gus` (unstage), `glst` (last commit)
- `pubkey-github` and `pubkey-codeberg` aliases replacing the old `pubkey`

### Changed
- Git signing switched from SSH to GPG (`gpg.format = openpgp`); signing key updated to GPG fingerprint
- `gc` abbreviation: removed redundant `-S` flag (signing handled globally by gitconfig)
- `gpg.conf`: updated stale comment that incorrectly stated git signing used SSH
- `ghostty/config`: `shell-integration` changed from `detect` to `fish`
- `newdoc`: author pulled from `git config user.name` instead of hardcoded string
- `aliases.fish`: `update-theme` uses `$HOME` instead of hardcoded absolute path
- Forgejo CI workflow: consolidated `apt-get` installs into one step; added comment noting Codeberg has no runners
- gitconfig: removed redundant aliases (`st`, `co`, `cb`, `br`, `ci`) covered by fish abbreviations

### Removed
- `git/allowed_signers` — no longer needed after switching to GPG signing
- `buo/cask-upgrade` tap from Brewfile — `brew upgrade --cask` covers this natively
- SSH `ControlMaster`/`ControlPersist`/`ControlPath` from GitHub host (unsupported by GitHub)
- Fallback `IdentityFile ~/.ssh/id_ed25519` from `Host *`

---

## 2026-06-01 — Vale: add prose linting packages

### Added
- `general/vale.ini`: added proselint, write-good, Readability, and alex as Vale packages and base styles
- `Makefile` (`vale` target): now runs `vale sync` automatically after writing `~/.vale.ini`

---

## 2026-06-01 — Audit fixes: hardening, guards, documentation

### Added
- Brewfile: `bash`, `kagi for safari`, `StopTheMadness`, `StopTheScript`, `Vinegar`
- `cdf`, `pman`, `o`: macOS guard — print clear error and return 1 on Linux
- `aliases.fish`: macOS-only aliases (`network`, `showfiles`, `hidefiles`, `flushdns`, `pubkey`, `cb`, `cv`) wrapped in `if test (uname) = Darwin`
- `cdf`: error message when no Finder window is open
- `make apps`: auto-installs Homebrew via the official script if `brew` is not found
- `make git`: warns if `delta` is not installed before symlinks are written
- `make brewauto`: runs `plutil -lint` on both generated plists before loading them
- README: "Verify your setup" block with `make doctor` and spot-check commands
- README: lazy-lock update instructions (`:Lazy update` + commit)
- README: templates section expanded with copy commands and CSL path explanation

### Changed
- `gpg-agent.conf` renamed to `gpg-agent.conf.tmpl`; `make auth` now generates the resolved file into the dotfiles dir and symlinks it (`~/.gnupg/gpg-agent.conf` → `general/gpg-agent.conf`); generated file is gitignored
- `make doctor`: gpg-agent check upgraded from `-f` (file exists) to `-L` (is a symlink)
- `git/gitconfig`: `signingkey` changed from `~/.ssh/id_ed25519.pub` to absolute path to guarantee expansion across all Git versions
- `launchd/org.jaredeberle.brewupdate.plist`: removed redundant `EnvironmentVariables`/`PATH` block — `homebrewupdate.sh` resolves `brew` itself
- `newdoc`: CSL path hardcoded to `$HOME/.dotfiles/templates/chicago-notes-bibliography-17th-edition.csl`
- README: Git section notes `delta` must be installed before `make git`

## 2026-06-01 — Go removal; MacTeX → BasicTeX; Neovim cleanup; SSH/GPG hardening

### Changed
- Neovim: removed `go` treesitter parser and FileType pattern (`editor.lua`)
- Neovim: `nvim-cmp` `<CR>` confirm changed to `select = false` (explicit selection only)
- Neovim: Twilight now activates automatically with ZenMode (`writing.lua`)
- Neovim: `mini.icons` wired as lualine dependency for file-type icons (`ui.lua`)
- SSH: moved `UseKeychain`, `AddKeysToAgent`, and multiplexing options from
  `Host *` to `Host codeberg` only; multiplexing added to codeberg for future hosts
- GPG: removed unused `default-cache-ttl-ssh` / `max-cache-ttl-ssh` from
  `gpg-agent.conf` (gpg-agent is not brokering SSH)

## 2026-06-01 — Go removal; MacTeX → BasicTeX; Brewfile housekeeping

### Changed
- Removed Go toolchain from Brewfile (`go`, `golang-migrate`, `gopls`) and from
  Neovim LSP config (`gopls` wired out of `lsp.lua`, `go` filetype removed)
- Replaced `mactex` cask with `basictex` (~100 MB vs 17 GB); added `tlmgr install`
  command to README and Quick Start table for the packages required by the CV and
  syllabus templates (`sourcesanspro` → `sourcesans` is the correct TeX Live name)

### Added
- Brewfile: `mas "dropover"` (id:1355679052) and `mas "folder quick look"`
  (id:6753110395) to match installed App Store apps

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
