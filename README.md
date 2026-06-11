# Dotfiles

A macOS-focused, speed-oriented development and **prose-writing** environment.
Everything is symlinked from `~/.dotfiles` via a `Makefile`, so a new machine
comes up the same as the old one. The editor (Neovim), terminal (Ghostty),
multiplexer (tmux), shell (fish), and color theme (**Nord**) are all
wired to work together.

> **Platform:** macOS only. It assumes Apple Silicon Homebrew (`/opt/homebrew`),
> uses `pbcopy`/`pbpaste`, `launchd`, `osascript`, and symlinks Ghostty into
> `~/Library/Application Support`. It will not work as-is on Linux.

---

## Table of Contents

- [Quick Start](#quick-start)
- [Check System](#check-system)
- [Makefile Options](#makefile-options)
- [Apps](#apps)
  - [Ghostty](#ghostty)
  - [Fish](#fish)
  - [Neovim](#neovim)
  - [tmux](#tmux)
  - [Git](#git)
  - [NeoMutt](#neomutt)
- [Prose and Pandoc](#prose-and-pandoc)
- [Scripting](#scripting)
  - [Bin](#bin)
  - [Launchd](#launchd)
- [Security](#security)
- [Repository Layout](#repository-layout)
- [Credits](#credits)

---

## Quick Start

```sh
# 1. Install the Xcode command-line tools (gives you git)
xcode-select --install

# 2. Clone this repo to the expected location (~/.dotfiles is hard-coded in the Makefile)
git clone --recurse-submodules https://codeberg.org/<you>/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 3. Install Homebrew (if needed) and all apps, CLIs, fonts (Brewfile)
make apps

# 4. Symlink all configs and install scheduled Homebrew jobs
make install

# 5. Apply macOS system defaults (keyboard repeat, Finder, Dock, screenshots, etc.)
make macos

# 6. Set fish as the login shell (requires sudo; open a new terminal afterwards)
make chsh

# 7. Write Firefox user.js (requires Firefox launched at least once first)
make firefox
```

Then finish the per-app setup:

| App       | One-time step                                                                               |
|-----------|---------------------------------------------------------------------------------------------|
| Firefox   | Launch Firefox once to create the profile, then run `make firefox`                          |
| Fish      | Run `make chsh` (requires sudo); open a new terminal afterwards                             |
| tmux      | Start `tmux`, press `Ctrl-a` then `I` to install plugins via TPM                           |
| Neovim    | Launch `nvim`; `lazy.nvim` bootstraps plugins and Tree-sitter parsers install automatically |
| NeoMutt   | Run `make neomutt`, edit `~/.mbsyncrc` and `~/.notmuch-config`, add Keychain entries, edit `local.rc`, run `mbsync -a && notmuch new`, then `make mailsync` |
| BasicTeX  | Run `make latex` to install the required `tlmgr` packages for PDF export                   |
| macOS     | Logout and back in for keyboard repeat changes to take full effect                          |

> **Why `~/.dotfiles`?** Every symlink in the `Makefile` is rooted at
> `$(HOME)/.dotfiles`. Cloning anywhere else will break the symlinks.

---

## Check System

All check targets print `WARNING: ... (run: make <target>)` for anything
missing or misconfigured. Use `dots <target>` to run from outside the
dotfiles directory (see [Fish → Functions](#fish)).

### Symlinks, keys, and shell

```sh
make doctor
```

Checks every symlink created by `make install`, plus: SSH keys exist
(`id_github`, `id_codeberg`), fish is set as the login shell, TPM is cloned,
vale styles directory is populated, and a GPG secret key is present.

### macOS defaults

```sh
make macos-check
```

Reads every key set by `make macos` and warns on any that are missing or set
to the wrong value. Run this after a macOS version upgrade to catch keys Apple
silently removed or changed.

### Brewfile packages

```sh
make brew-check
```

Runs `brew bundle check` to verify every package in the Brewfile is installed.
Fast way to spot drift after `brew cleanup` or a fresh clone.

### Tool binaries

```sh
make tools-check
```

Verifies that `delta`, `vale`, `pandoc`, `pandoc-crossref`, `lazygit`,
`lua-language-server`, `pyright`, `bash-language-server`, `stylua`, `black`,
and `prettier` are all on `PATH`.

### Maintenance

```sh
make clean
```

Removes stale directories left over from old repo layouts (`fish/` and
`general/` at the repo root) that git pull does not clean up automatically.
Run this once on any machine that had the repo checked out before the
2026-06-08 restructure.

---

## Makefile Options

Run `make <target>`. There is intentionally **no default** target (`make` alone
just prints a warning) so nothing destructive happens by accident.

| Target             | What it does                                                                                        |
|--------------------|-----------------------------------------------------------------------------------------------------|
| `install`          | Runs `apps git shell security nvim vale neomutt brewauto` in order, then `doctor`                   |
| `chsh`             | Adds fish to `/etc/shells` and sets it as the login shell via `dscl` (requires sudo)                |
| `git`              | Symlinks `gitconfig` → `~/.gitconfig`, `gitignore` → `~/.gitignore`, lazygit config                |
| `shell`            | Symlinks fish (`shell/fish/`), Ghostty, tmux, and bat configs                                       |
| `security`         | Symlinks SSH config + GPG configs; creates `~/.ssh/control` and `~/.gnupg` with safe perms          |
| `firefox`          | Detects the default Firefox profile via `installs.ini` and writes `user.js` (Betterfox + overrides) |
| `betterfox-update` | Pulls latest Betterfox upstream into the submodule; re-run `make firefox` afterwards               |
| `apps`             | `brew bundle` against `homebrew/brewfile` (CLIs, casks, fonts, Mac App Store apps)                 |
| `nvim`             | Symlinks the whole `writing/nvim/` dir → `~/.config/nvim`                                           |
| `vale`             | Writes a global `~/.vale.ini` with an absolute `StylesPath`, creates the styles dir, runs `vale sync` |
| `neomutt`          | Symlinks NeoMutt config files into `~/.config/neomutt/`, creates cache dirs, scaffolds `~/.mbsyncrc` and `~/.notmuch-config` from templates if missing |
| `mailsync`         | Installs a launchd agent that runs `mbsync -a && notmuch new` every 5 minutes                      |
| `brewauto`         | Installs `launchd` agents that update Homebrew weekly and rotate the log monthly                    |
| `latex`            | Installs the `tlmgr` packages required for PDF export (requires BasicTeX from `make apps`)          |
| `macos`            | Writes sensible macOS system defaults (keyboard repeat, Finder, Dock, screenshots, system)          |
| `macos-check`      | Reads every key set by `make macos` and warns on any that are missing or wrong value                |
| `brew-check`       | Runs `brew bundle check` to verify every Brewfile package is installed                              |
| `tools-check`      | Verifies key binaries are on `PATH`: delta, vale, pandoc, lazygit, LSP servers, and formatters      |
| `doctor`           | Checks symlinks, SSH keys, login shell, TPM, vale styles, and GPG key                              |
| `clean`            | Removes stale directories left over from old repo layouts (`fish/`, `general/`)                    |

---

## Apps

### Ghostty

The terminal config lives at `shell/ghostty/config` and is symlinked into
Application Support.

| Setting                        | Value                          | Notes                                           |
|--------------------------------|--------------------------------|-------------------------------------------------|
| `theme`                        | Nord                           | Matches Neovim, tmux, bat, fzf                  |
| `font-family` / `font-size`    | JetBrainsMono Nerd Font / 15   | Nerd Font for icons in `eza`, lualine, etc.     |
| `background-opacity` / blur    | `0.93` / `18`                  | Subtle translucency                             |
| `copy-on-select`               | `clipboard`                    | Selecting text copies it                        |
| `macos-option-as-alt`          | `true`                         | Makes `Option` send `Alt` for tmux `M-h`/`M-l`  |
| `mouse-hide-while-typing`      | `true`                         | —                                               |
| `cursor-style-blink`           | `false`                        | Steady cursor                                   |
| `window-save-state`            | `always`                       | Restores layout/working dirs after restart      |
| `shell-integration`            | `fish` + `cursor,sudo,title`   | Explicit fish integration; prompt/cursor reporting for Neovim |

> Reload Ghostty config with **`Cmd-Shift-,`**.

---

### Fish

Configured for speed: external tool initializations (`fzf`, `zoxide`) are
**cached to disk** and only regenerated when the binary is newer than the
cache. Autosuggestions, syntax highlighting, and completions are
built into fish, so there are no shell plugins to source or `compinit` to run.

- `conf.d/env.fish` — environment (`EDITOR=nvim`, `PAGER="bat --style=plain"`,
  `MANPAGER="nvim +Man!"`, `BAT_THEME`, `LS_COLORS`, `HOMEBREW_NO_ANALYTICS`,
  `HOMEBREW_NO_ENV_HINTS`), PATH (`~/.dotfiles/bin`, `~/.local/bin`), and the
  Homebrew shellenv.
  `conf.d/*.fish` is auto-sourced for every session.
- `conf.d/options.fish` — documents how zsh `setopt`s map to fish defaults and
  disables the startup greeting.
- `conf.d/aliases.fish` — see below.
- `config.fish` — interactive setup: keybindings, fzf, zoxide.
- `functions/` — autoloaded functions (see below).
- `functions/fish_prompt.fish` — native fish prompt: directory (Nord purple),
  git branch (Nord yellow), git status indicators (Nord blue), prompt character
  (green ❯ on success, red on error). No external dependency.

#### Shell behavior

- **History:** **shared** across sessions, de-duplicated, and effectively
  unbounded — all by default (no `HISTSIZE`/`SHARE_HISTORY` to configure).
- **Autosuggestions** and **syntax highlighting** are built in (replacing
  `zsh-autosuggestions`/`zsh-syntax-highlighting`), as are man-page-backed
  **completions** (no `compinit`).
- **Directory history** — `prevd`/`nextd` (Alt-←/→) and `cd -` cover the
  `AUTO_PUSHD` workflow; `**` recursive globbing is built in.
- **Gaps vs zsh:** fish has no `AUTO_CD` (use `cd`, or zoxide's `z`), no
  `NO_CLOBBER` (`>` overwrites — use `>>`), and no `HIST_IGNORE_SPACE`.

#### Keybindings

| Keys                       | Action                                            |
|----------------------------|---------------------------------------------------|
| `Ctrl-←` / `Ctrl-→`        | Move by word                                      |
| `↑` / `↓`                  | History search seeded by what you've typed        |
| `Ctrl-R`                   | fzf fuzzy history search                          |
| `Ctrl-T`                   | fzf file picker (uses `fd`, `bat` preview)        |
| `Alt-C`                    | fzf `cd` into a subdirectory (`eza` tree preview) |

#### zoxide

`z <partial>` jumps to a frecency-ranked directory; `zi` opens an interactive
picker.

#### Aliases

**Editor & files**

| Alias       | Expands to                                              |
|-------------|---------------------------------------------------------|
| `v`, `vim`  | `nvim`                                                  |
| `cat`       | `bat`                                                   |
| `ls`        | `eza --icons`                                           |
| `ll`        | `eza -lh --git --icons --group-directories-first`       |
| `la`        | `eza -lah --git --icons --group-directories-first`      |
| `lt`        | `eza --tree --level=2 --icons`                          |
| `ltt`       | `eza --tree --level=3 --icons`                          |
| `recent`    | `eza -lah --sort=modified`                              |
| `biggest`   | `eza -lah --sort=size --reverse`                        |
| `findd`     | `fd --type d`                                           |
| `findf`     | `fd --type f`                                           |

**Safety & navigation**

| Alias                | Expands to                               |
|----------------------|------------------------------------------|
| `cp` / `mv`          | `cp -i` / `mv -i` (prompt before clobber)|
| `..` / `...` / `....`| `cd ..` / `cd ../..` / `cd ../../..`     |
| `reload`             | `exec fish`                              |
| `paths`              | Print `$PATH` one entry per line         |

**Clipboard & keys**

| Alias            | Expands to                                         |
|------------------|----------------------------------------------------|
| `cb`             | `pbcopy` (pipe into it: `echo hi \| cb`)           |
| `cv`             | `pbpaste`                                          |
| `pubkey-github`  | Copy `~/.ssh/id_github.pub` to the clipboard       |
| `pubkey-codeberg`| Copy `~/.ssh/id_codeberg.pub` to the clipboard     |

**System / network / housekeeping**

| Alias                     | Purpose                                                       |
|---------------------------|---------------------------------------------------------------|
| `myip`                    | Public IP via `ifconfig.me`                                   |
| `ports`                   | Listening TCP ports (`lsof`)                                  |
| `network`                 | `networkQuality` speed test                                   |
| `disk`                    | `df -h` — free/used space per mount                           |
| `usage`                   | `du -sh -- *` — directory sizes in cwd (pairs with `biggest`) |
| `brewup`                  | `brew update && upgrade && cleanup`                           |
| `flushdns`                | Flush the macOS DNS cache                                     |
| `cleands`                 | Delete `.DS_Store` files under the current tree               |
| `showfiles` / `hidefiles` | Toggle hidden files in Finder                                 |

**Git**

| Abbr   | Expands to                                              |
|--------|---------------------------------------------------------|
| `lg`   | `lazygit`                                               |
| `gs`   | `git status -sb`                                        |
| `ga`   | `git add`                                               |
| `gc`   | `git commit`                                            |
| `gp`   | `git push`                                              |
| `gpl`  | `git pull`                                              |
| `gf`   | `git fetch`                                             |
| `gd`   | `git diff` (rendered by delta)                          |
| `gds`  | `git diff --staged`                                     |
| `gl`   | `git log --oneline --graph --decorate -20`              |
| `glo`  | `git log --graph --decorate --oneline --all`            |
| `gco`  | `git checkout`                                          |
| `gb`   | `git branch`                                            |
| `grst` | `git restore`                                           |
| `gund` | `git reset --soft HEAD~1` (undo last commit)            |
| `gus`  | `git restore --staged` (unstage)                        |
| `glst` | `git log -1 HEAD` (show last commit)                    |

#### Functions (`shell/fish/functions/`)

Autoloaded — call them like commands.

| Function                | Usage / behavior                                                                      |
|-------------------------|---------------------------------------------------------------------------------------|
| `dots <target>`         | Run a dotfiles `make` target from any directory (`dots doctor`, `dots install`, etc.) |
| `acp <message>`         | **a**dd, signed **c**ommit, **p**ush in one step (quotes optional)                    |
| `newdoc <file> [title]` | Create a Markdown file pre-filled with Pandoc metadata and open in Neovim             |
| `bb [path]`             | Launch BBEdit; with a dir, open **and** `cd` into it                                  |
| `cdf`                   | `cd` to the directory open in the front Finder window                                 |
| `fn <text>`             | List files whose name contains `<text>` (recursive glob)                              |
| `fuck`                  | Re-run the previous command under `sudo`                                              |
| `gpg-master-import`     | Import the offline GPG master key from USB for editing                                |
| `gpg-master-done`       | Remove master key and reimport machine-specific subkeys only                          |
| `mkd <dir>`             | `mkdir -p` then `cd` into it                                                          |
| `o [paths]`             | `open` the current dir (no args) or the given paths                                   |
| `pman <cmd>`            | Open a man page rendered as a PDF in Preview                                          |
| `wordfrequency`         | Read stdin, print word counts sorted high→low (great for prose)                       |

---

### Neovim

A lean, **prose-first** Neovim config built on `lazy.nvim`. The emphasis is
fast startup (almost everything is lazy-loaded), Markdown/Pandoc authoring, and
just enough LSP for the languages used in `bin/` (Lua, Python, Bash).

**Leader key:** `,` (comma)

#### Layout

```
writing/nvim/
├── init.lua                 # loads the modules below
├── lazy-lock.json           # pinned plugin commits (committed for reproducibility)
└── lua/
    ├── config/
    │   ├── options.lua      # editor options
    │   ├── keymaps.lua      # global key mappings
    │   ├── autocmds.lua     # filetype + focus autocommands
    │   └── lazy.lua         # bootstraps lazy.nvim
    └── plugins/
        ├── ui.lua           # nord theme + lualine
        ├── editor.lua       # oil, telescope, treesitter, gitsigns
        ├── completion.lua   # blink.cmp
        ├── lsp.lua          # lspconfig + conform (formatting)
        ├── linting.lua      # nvim-lint (vale)
        ├── markdown.lua     # render-markdown
        └── writing.lua      # zen-mode, twilight, mini.nvim
```

#### Key mappings

| Keys          | Mode   | Action                                              |
|---------------|--------|-----------------------------------------------------|
| `<leader>w`   | Normal | Write (save) the buffer                             |
| `<leader>q`   | Normal | Quit the window                                     |
| `<leader>ff`  | Normal | Telescope **f**ind **f**iles                        |
| `<leader>fg`  | Normal | Telescope live **g**rep                             |
| `<leader>fb`  | Normal | Telescope **b**uffers                               |
| `<leader>z`   | Normal | Toggle **Zen mode** (distraction-free writing)      |
| `-`           | Normal | Open **Oil** file browser in the current dir        |
| `<leader>cf`  | Normal | **C**onform **f**ormat the buffer                   |
| `<leader>ph`  | Normal | **P**andoc export → **H**TML (citeproc + crossref)  |
| `<leader>pp`  | Normal | **P**andoc export → **P**DF (citeproc + crossref)   |
| `<CR>`        | Insert | Confirm the selected completion item                |

**From `mini.nvim` (defaults):**

| Keys           | Action                                                        |
|----------------|---------------------------------------------------------------|
| `gcc`          | Toggle comment on the current line                            |
| `gc` + motion  | Toggle comment over a motion / visual selection               |
| `sa` + motion  | **S**urround **a**dd (e.g. `saiw"` wraps a word in quotes)    |
| `sd`           | **S**urround **d**elete (`sd"`)                               |
| `sr`           | **S**urround **r**eplace (`sr"'`)                             |
| (auto)         | `mini.pairs` auto-closes brackets/quotes                      |

#### Notable options (`options.lua`)

| Option                         | Value             | Why                                              |
|--------------------------------|-------------------|--------------------------------------------------|
| `clipboard`                    | `unnamedplus`     | Yanks sync with the macOS clipboard / `pbpaste`  |
| `wrap` + `linebreak`           | on                | Soft-wrap prose at word boundaries               |
| `textwidth` / `colorcolumn`    | `80` / `81`       | Visual guide for prose width                     |
| `spell` (per-filetype)         | on for md/text    | Spell-check prose only, not code                 |
| `conceallevel`                 | `2` (md)          | Lets `render-markdown` hide syntax markers       |
| `undofile`                     | on                | Persistent undo across sessions                  |
| `updatetime` / `timeoutlen`    | `250` / `300` ms  | Snappy diagnostics + which-key-style timing      |
| `ignorecase` + `smartcase`     | on                | Case-insensitive search until you type a capital |

#### Plugins

- **Theme/UI:** `gbprod/nord.nvim`, `lualine` (globalstatus).
- **Navigation:** `telescope` (lazy on `:Telescope`), `oil` (`-`), `gitsigns`.
- **Syntax:** `nvim-treesitter` (**`main` branch** — parsers install
  automatically on first launch; highlighting starts per-filetype).
- **Writing:** `render-markdown`, `zen-mode`, `twilight`, `mini.nvim`
  (`pairs`, `comment`, `surround`).
- **LSP:** `nvim-lspconfig` for `lua_ls`, `pyright`, `bashls` (loads only for
  those filetypes).
- **Completion:** `blink.cmp` (lsp + buffer + path sources, all built in —
  no separate source plugins) with the built-in `vim.snippet` expander;
  loads on `InsertEnter`. Enter confirms only an explicitly selected item.
- **Formatting:** `conform.nvim` — `stylua` (Lua), `black` (Python),
  `prettier` (Markdown). Trigger with `<leader>cf`.
- **Linting:** `nvim-lint` runs `vale` on Markdown (read/save) — see
  [Prose and Pandoc](#prose-and-pandoc).

> **Plugin pins:** `lazy-lock.json` is committed so every machine gets the same
> plugin versions. To update all plugins to their latest commits, run `:Lazy update`
> inside Neovim, then commit the resulting `lazy-lock.json` change.

> All LSP servers, formatters, and linters are installed by the Brewfile
> (`lua-language-server`, `pyright`, `bash-language-server`, `stylua`,
> `black`, `prettier`, `vale`) — there is no Mason layer.

---

### tmux

**Prefix:** `Ctrl-a` (remapped from the default `Ctrl-b`). Press `Ctrl-a`
twice to send a literal `Ctrl-a` to the underlying program.

#### Key bindings

| Keys (after prefix unless noted) | Action                                            |
|----------------------------------|---------------------------------------------------|
| `-`                              | Split into top/bottom panes (in current dir)      |
| `_`                              | Split into left/right panes (in current dir)      |
| `h` / `j` / `k` / `l`           | Move between panes (Vim directions)               |
| `H` / `J` / `K` / `L`           | Resize the pane by 5 cells (repeatable)           |
| `c`                              | New window in the current directory               |
| `Tab`                            | Jump to the last (previous) window                |
| `z`                              | Zoom / unzoom the current pane                    |
| `r`                              | Reload `~/.tmux.conf`                             |
| `I`                              | (TPM) install plugins                             |
| `Option-h` / `Option-l`         | **No prefix** — previous / next window            |

**Copy mode (Vi keys):** enter with `Ctrl-a [`.

| Keys              | Action                                       |
|-------------------|----------------------------------------------|
| `v`               | Begin selection                              |
| `y`               | Copy selection → macOS clipboard (`pbcopy`)  |
| mouse drag        | Copy on release → clipboard                  |

#### Behavior & options

- **Mouse** support on; **256-color + true color** via `tmux-256color`.
- `escape-time 0` and `focus-events on` for responsive Neovim integration
  (the Neovim config calls `checktime` on focus to auto-reload changed files).
- Windows/panes are **1-indexed** and **renumber** when one closes.
- `history-limit` is 100,000 lines.
- `terminal-features` passes **RGB true color**, **colored underlines**
  (undercurl diagnostics in Neovim), and **cursor-shape** changes through
  (block in normal, beam in insert).
- **Plugins** (via TPM): `tpm`, `nordtheme/tmux`. The status line
  is composed from Nord modules (session on the left, date/time on the right).

---

### Git

GPG commit/tag **signing** is enabled (`gpg.format = openpgp`, signing key is
the GPG primary key fingerprint). The same key is registered on both GitHub and
Codeberg. `delta` is the pager/diff renderer (Nord theme) — it must be installed
before `make git` is run, or `git diff`/`git log` will fail. `make apps` installs it.

**Sensible defaults baked in:** `pull.rebase`, `push.autoSetupRemote` +
`default = current`, `rebase.autoStash` + `updateRefs`, `fetch.prune`,
`rerere.enabled`, `diff.algorithm = histogram`, `merge.conflictstyle = zdiff3`,
`help.autocorrect = prompt`, `init.defaultBranch = main`, branches sorted by
most-recent commit.

#### Git aliases

| Alias         | Command                                                          |
|---------------|------------------------------------------------------------------|
| `git amend`   | `commit --amend`                                                 |
| `git undo`    | `reset --soft HEAD~1` (undo last commit, keep changes)           |
| `git last`    | `log -1 HEAD`                                                    |
| `git lg`      | Pretty graph log                                                 |
| `git lol`     | `log --graph --decorate --oneline --all`                         |
| `git unstage` | `restore --staged`                                               |
| `git discard` | `restore` (discard working-tree changes)                         |

---

### NeoMutt

A local-first mail setup: **Proton Bridge** exposes Proton Mail over local
IMAP/SMTP, **mbsync** syncs it to a local Maildir (`~/.mail/proton/`),
**notmuch** indexes it for fast full-text search, and **NeoMutt** reads the
local Maildir and sends via the Bridge. A launchd agent keeps everything in
sync every 5 minutes in the background.

| Layer      | Tool                 | Purpose                                                |
|------------|----------------------|--------------------------------------------------------|
| Gateway    | Proton Bridge        | Decrypts Proton Mail locally; IMAP `127.0.0.1:1143`, SMTP `127.0.0.1:1025` |
| Sync       | mbsync (isync)       | Syncs Bridge IMAP → `~/.mail/proton/` Maildir          |
| Index      | notmuch              | Full-text search over the local Maildir                |
| Client     | NeoMutt              | Reads local Maildir; sends via Bridge SMTP             |
| Background | launchd              | Runs `mailsync` every 5 minutes                        |

The Bridge must be running for sync and send to work — the background sync
exits quietly when it isn't.

#### One-time setup

`make neomutt` symlinks the four config files, creates cache directories,
creates `~/.mail/proton/`, and copies `mbsyncrc` + `notmuch-config` templates
if they don't already exist.

1. **Install and sign in to Proton Bridge**, and note the password it
   generates (Bridge → account → show password). The same password is used
   for IMAP and SMTP.

2. **Run `make neomutt`** to scaffold everything.

3. **Edit `~/.mbsyncrc`** — set `User` to your Proton Bridge email address.

4. **Edit `~/.notmuch-config`** — set `name` and `primary_email`
   (`path` is filled in automatically by `make neomutt`).

5. **Store the Bridge password in Keychain** under a custom service name
   (avoids conflicts with Apple Mail's tokens stored under server hostnames):
   ```fish
   read -s -P "Bridge password: " PASS
   security add-internet-password -s "proton-bridge" -a "neomutt" -T /usr/bin/security -w $PASS
   ```

6. **Edit `~/.config/neomutt/accounts/local.rc`** — use
   `writing/neomutt/accounts/example.rc` as the template. Key settings:
   - `set folder = ~/.mail/proton` — local Maildir root
   - `set nm_default_url = "notmuch:///Users/you/.mail"` — absolute path
   - `set smtp_url` — authenticate as your Bridge login, `From` uses your custom domain
   - `smtp_pass` backtick must be wrapped in double quotes to handle `%` in passwords
   - On first send, accept the Bridge's self-signed certificate; it persists
     in the file set by `certificate_file`

7. **Initial sync** (Bridge running):
   ```sh
   mbsync -a && notmuch new
   ```

8. **Install background sync:**
   ```sh
   make mailsync
   ```

After this, use `mailsync` in the terminal to sync on demand, or let launchd
handle it automatically. Logs go to `~/.local/mail_sync_logs.txt`.

#### Keybindings

| Key              | Mode            | Action                                         |
|------------------|-----------------|------------------------------------------------|
| `A`              | Index / Pager   | Archive message to `=Archive`                  |
| `B`              | Index / Pager   | Open sidebar folder                            |
| `Ctrl-F`         | Index           | Search mail with notmuch (vfolder-from-query)  |
| `Ctrl-U`         | Index / Pager   | Extract and open URLs via urlscan              |
| `Ctrl-P` / `Ctrl-N` | Index / Pager | Previous / next sidebar item                |
| `\Ch`            | Attach / Compose | Open HTML in Firefox                          |
| `Ctrl-R`         | Index           | Mark all messages as read                      |

#### GPG/PGP

`writing/neomutt/gpg.rc` uses GPGME with the same key and `gpg.conf` managed
by `make security`. Encrypted replies are automatically encrypted; signed
messages are automatically verified. Toggle signing/encryption per message with
`p` in the compose menu.

#### HTML rendering

HTML emails render inline via `w3m`. Press `\Ch` to open in Firefox instead.
Both `w3m` and `urlscan` are in the Brewfile.

#### Aliases

`mutt` is aliased to `neomutt`; both commands launch the client.

---

## Prose and Pandoc

This setup is tuned for academic / long-form writing in Markdown.

- **Live rendering** in Neovim via `render-markdown.nvim` (LaTeX module
  disabled — no `latex` parser installed).
- **Linting** via `vale`. `make vale` writes a global `~/.vale.ini` with an
  absolute `StylesPath` (`~/.local/share/vale/styles`) and runs `vale sync` to
  download the configured packages: `proselint`, `write-good`, `Readability`,
  and `alex`. A per-project `.vale.ini` placed in a repo overrides the global one.
- **Templates** in `writing/pandoc/`:
  - `metadata.yaml` — Pandoc metadata block (title, author, `bibliography`,
    `geometry`, `fontsize`, `linestretch`). Copy it next to a document and edit:
    ```sh
    cp ~/.dotfiles/writing/pandoc/metadata.yaml .
    ```
  - `chicago-notes-bibliography-17th-edition.csl` — CSL style file referenced
    automatically by `newdoc` (hardcoded to `~/.dotfiles/writing/pandoc/`). Pandoc
    exports via `<leader>ph`/`<leader>pp` will resolve it from there.
  - `vale-project.ini` — a per-project Vale config (relative `StylesPath`). Copy to a
    project root to override the global `~/.vale.ini`:
    ```sh
    cp ~/.dotfiles/writing/vale/vale-project.ini .
    ```
- **Export** with `<leader>ph` (HTML) or `<leader>pp` (PDF). Both:
  - run `pandoc --filter pandoc-crossref --citeproc` (cross-references resolve
    *before* citations),
  - `cd` into the document's own directory first, so relative paths in
    `metadata.yaml` (bibliography, CSL) and relative images resolve correctly,
  - auto-add `--metadata-file=metadata.yaml` when a sibling file exists.
- PDF export uses the LaTeX engine from **BasicTeX** (installed via the Brewfile
  cask). After `make apps`, install the packages required by the CV and syllabus
  templates:

```sh
make latex
```

---

## Scripting

### Bin

Scripts in `bin/` are on `PATH` via `shell/fish/conf.d/env.fish`. The Python
scripts use [`uv`](https://docs.astral.sh/uv/)'s inline (PEP 723) dependencies
— no venv to manage.

| Script                              | Purpose                                                                                                              |
|-------------------------------------|----------------------------------------------------------------------------------------------------------------------|
| `ipic -i\|-m\|-a\|-f\|-t\|-b TERM`  | Build an HTML gallery of iTunes/App Store artwork and open it. Flags: `-i` iOS app, `-m` Mac app, `-a` album, `-f` film, `-t` TV, `-b` book. |
| `waybackup <URL>`                   | Save a URL to the Internet Archive Wayback Machine; prints the snapshot URL.                                         |
| `homebrewupdate.sh`                 | `brew update` + `outdated` + `upgrade`, with timestamped log output.                                                 |
| `homebrewlogclean.sh`               | Delete the update log — but only on the **first Monday** of the month.                                               |
| `mailsync.sh`                       | `mbsync -a` + `notmuch new` with timestamped log output; invoked by the mailsync launchd agent.                      |

### Launchd

`make brewauto` and `make mailsync` install user LaunchAgents (`__HOME__` is
substituted with your real home at install time):

| Agent                             | Schedule        | Runs                                                                  |
|-----------------------------------|-----------------|-----------------------------------------------------------------------|
| `org.jaredeberle.brewupdate`      | Mondays 09:00   | `bin/homebrewupdate.sh`                                               |
| `org.jaredeberle.brewlogclean`    | Mondays 08:00   | `bin/homebrewlogclean.sh` (self-gates to the first Monday)            |
| `org.jaredeberle.mailsync`        | Every 5 minutes | `bin/mailsync.sh`                                                     |

Logs: `~/.local/brew_update_logs.txt` (newest run first), `~/.local/mail_sync_logs.txt`. Trigger a run on demand:

```sh
launchctl kickstart -k gui/$(id -u)/org.jaredeberle.brewupdate
launchctl kickstart -k gui/$(id -u)/org.jaredeberle.mailsync
```

---

## Security

Installed by `make security`.

- **SSH** (`security/ssh-config`): dedicated key per host (`id_github`,
  `id_codeberg`), modern crypto only — hybrid post-quantum key exchange first
  (ML-KEM / sntrup761 + x25519), AEAD-only ciphers (AES-256-GCM preferred,
  ChaCha20-Poly1305 fallback), `IdentitiesOnly`, agent + Keychain integration,
  strict host-key checking,
  connection multiplexing for Codeberg (`ControlPath ~/.ssh/control/%C`,
  persisted 10m), no agent/X11 forwarding. Includes a `github-443` fallback
  host alias for networks that block port 22.
- **GPG** (`security/gpg.conf`, `gpg-agent.conf.tmpl`, `dirmngr.conf`, `common.conf`):
  hardened algorithm preferences (AES-256 / SHA-512), strong S2K, `pinentry-mac`,
  `import-minimal`/`export-minimal`, `no-allow-loopback-pinentry`, `use-keyboxd`
  (`common.conf`), privacy-conscious keyserver/dirmngr defaults (LDAP disabled).
  Git commit and tag signing uses GPG (`gpg.format = openpgp`) — the same key
  works across GitHub and Codeberg without cross-registering SSH keys.
- **GPG master key management**: `gpg-master-import` / `gpg-master-done` fish
  functions handle the import-edit-cleanup cycle for the offline master key.
  `gpg-master-done` detects the machine (Leia/Ahsoka) and reimports only the
  correct machine-specific subkeys.
- **Firefox** (`security/betterfox/` submodule + `security/user-overrides.js`):
  `make firefox` concatenates both into a single `user.js` written to the active
  Firefox profile. Personal overrides (Smoothfox scroll tuning, DoH/NextDNS,
  shutdown sanitizing, etc.) live in `user-overrides.js` — Betterfox itself is
  never edited. To update Betterfox: `make betterfox-update`, review the diff,
  then `make firefox`.

---

## Repository Layout

```
.dotfiles/
├── Makefile              # symlink/install targets
├── README.md
├── bin/                  # scripts on $PATH (brew jobs, ipic, waybackup)
├── security/             # ssh, gpg, dirmngr, firefox configs
│   ├── betterfox/        # Betterfox submodule (upstream user.js — never edited)
│   └── user-overrides.js # personal Firefox prefs appended on top of Betterfox
├── git/                  # gitconfig, gitignore, lazygit.yml
├── homebrew/             # Brewfile + LaunchAgent plist templates
├── shell/                # all terminal/shell environment configs
│   ├── bat/              # bat pager config
│   ├── fish/             # config.fish, conf.d, functions
│   ├── ghostty/          # terminal emulator config
│   └── tmux.conf         # tmux config
└── writing/              # editor, Pandoc templates, Vale configs, and mail
    ├── nvim/             # Neovim config (see Neovim section)
    ├── neomutt/          # NeoMutt config (neomuttrc, gpg.rc, colors.rc, mailcap, mbsyncrc, notmuch-config, plist)
    ├── pandoc/           # metadata.yaml, CSL, reference.docx
    └── vale/             # global vale.ini + vale-project.ini template
```

---

## Credits

Many of these files have been refined over years from sources I've mostly
forgotten — if something here deserves attribution, let me know. The `ipic`
script is originally by [Dr. Drang](https://github.com/drdrang/ipic).
