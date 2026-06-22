# Dotfiles

A macOS-focused, speed-oriented development and **prose-writing** environment.
Everything is symlinked from `~/.dotfiles` via a `Makefile`, so a new machine
comes up the same as the old one. The editor (Neovim), terminal (Ghostty),
multiplexer (tmux), shell (fish), and color theme (**Nord**) are all
wired to work together.

> **Platform:** macOS only, Apple Silicon (Homebrew at `/opt/homebrew`). It uses
> `pbcopy`/`pbpaste`, `launchd`, `osascript`, Automator services, and symlinks
> Ghostty into `~/Library/Application Support`.

**Note**: I had Claude write this up largely so I know where to look when something breaks or I forget a command, if something doesn't make sense, it's probably really internal for my system. Feel free to reach out but all of this is beyond my abilities to troubleshoot.

---

## Table of Contents

- [Quick Start](#quick-start)
- [Check System](#check-system)
- [Makefile Options](#makefile-options)
- [Prose and Pandoc](#prose-and-pandoc)
  - [Neovim](#neovim)
  - [Writing functions and aliases (fish)](#writing-functions-and-aliases-fish)
- [Apps](#apps)
  - [Ghostty](#ghostty)
  - [Fish](#fish)
  - [tmux](#tmux)
  - [Git](#git)
  - [NeoMutt](#neomutt)
- [Scripting](#scripting)
  - [Bin](#bin)
  - [Launchd](#launchd)
  - [macOS Services](#macos-services)
- [Security](#security)
  - [SSH key custody (Secretive)](#ssh-key-custody-secretive)
  - [Optional system hardening (separate targets)](#optional-system-hardening-separate-targets)
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
| macOS     | Logout and back in for keyboard repeat changes to take full effect                          |

> **Why `~/.dotfiles`?** Every symlink in the `Makefile` is rooted at
> `$(HOME)/.dotfiles`. Cloning anywhere else will break the symlinks.

---

## Check System

All check targets print `WARNING: ... (run: make <target>)` for anything
missing or misconfigured. Run them all at once with **`make check`**
(`doctor` + `macos-check` + `brew-check` + `tools-check`); `brew-drift` stays
separate since it's informational. Use `dots <target>` to run from outside the
dotfiles directory (see [Fish → Functions](#fish)).

### Symlinks, keys, and shell

```sh
make doctor
```

Checks every symlink created by `make install`, plus: SSH keys exist
(`id_github`, `id_codeberg`), `~/.ssh`/`~/.gnupg` and the private keys are
owner-only (no group/other access), fish is set as the login shell, TPM is
cloned, vale styles directory is populated, a GPG secret key is present, and any
installed launchd agents (mailsync, brewupdate, brewlogclean, resticcheck) are
actually loaded — not just that their plist files exist.

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

Verifies that `delta`, `vale`, `pandoc`, `pandoc-crossref`, `tectonic`, `lazygit`, `harper-ls`,
`marksman`, `lua-language-server`, `pyright`, `bash-language-server`, `stylua`, `black`,
and `prettier` are all on `PATH`.

### Brewfile drift (reverse direction)

```sh
make brew-drift
```

Lists formulae/casks that are **installed but not in the Brewfile** — the
reverse of `make brew-check`. Catches ad-hoc `brew install`s that would vanish
on the next machine. Informational only (a dry run); deliberately-untracked
items will also appear, so it never removes anything.

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
| `install`          | Runs `apps git shell security nvim vale neomutt services brewauto` in order, then `doctor`          |
| `chsh`             | Adds fish to `/etc/shells` and sets it as the login shell via `dscl` (requires sudo)                |
| `git`              | Symlinks `gitconfig`/`gitignore`/`gitmessage` + lazygit config; makes the `git/hooks/pre-commit` (gitleaks) hook executable |
| `shell`            | Symlinks fish (`shell/fish/`), Ghostty, tmux, and bat configs                                       |
| `security`         | Symlinks SSH config + pinned `known_hosts` + GPG configs; creates `~/.ssh/control` and `~/.gnupg` with safe perms |
| `firefox`          | Detects the default Firefox profile via `installs.ini` and writes `user.js` (Betterfox + overrides) |
| `betterfox-update` | Pulls latest Betterfox upstream into the submodule; re-run `make firefox` afterwards               |
| `apps`             | `brew bundle` against `homebrew/brewfile` (CLIs, casks, fonts, Mac App Store apps)                 |
| `nvim`             | Symlinks the whole `writing/nvim/` dir → `~/.config/nvim`                                           |
| `vale`             | Writes a global `~/.vale.ini` with an absolute `StylesPath`, creates the styles dir, runs `vale sync` |
| `neomutt`          | Symlinks NeoMutt config files into `~/.config/neomutt/`, creates cache dirs, scaffolds `~/.mbsyncrc` and `~/.notmuch-config` from templates if missing |
| `mailsync`         | Installs a launchd agent that runs `mbsync -a && notmuch new` every 5 minutes                      |
| `resticcheck`      | Installs a launchd agent that runs `archbackup check` (restic integrity) weekly; no-op when the backup drive is unmounted |
| `brewauto`         | Installs `launchd` agents that update Homebrew weekly and rotate the log monthly                    |
| `macos`            | Writes sensible macOS system defaults (keyboard repeat, Finder, Dock, screenshots, system)          |
| `macos-check`      | Reads every key set by `make macos` plus the security checks (FileVault, firewall, auto-updates, Touch ID) and warns on any missing/wrong |
| `harden`           | **(sudo)** Enables the application firewall + stealth mode, automatic macOS security updates, and opts out of Apple diagnostics submission |
| `touchid`          | **(sudo)** Writes `/etc/pam.d/sudo_local` to enable Touch ID for `sudo` (with `pam_reattach` so it works inside tmux) |
| `brew-check`       | Runs `brew bundle check` to verify every Brewfile package is installed                              |
| `brew-drift`       | Lists formulae/casks installed but **not** in the Brewfile (reverse of `brew-check`; dry run)       |
| `tools-check`      | Verifies key binaries are on `PATH`: delta, vale, pandoc, lazygit, LSP servers, and formatters      |
| `update`           | Updates the non-brew toolchain — Neovim plugins (Lazy sync), tmux TPM, `vale sync`; Homebrew/Betterfox stay on their own paths |
| `doctor`           | Checks symlinks, SSH keys, key/secret-dir permissions, login shell, TPM, vale styles, GPG key, git hooksPath/gitleaks, FileVault, and that launchd agents are loaded |
| `check`            | Runs all read-only health checks at once: `doctor` + `macos-check` + `brew-check` + `tools-check` |
| `clean`            | Removes stale directories left over from old repo layouts (`fish/`, `general/`)                    |

`harden` and `touchid` are **not** part of `make install` — they touch system
files under `sudo`, so run them deliberately. `resticcheck` is optional and only
useful once `archbackup` is configured (see the Security section).

---

## Prose and Pandoc

This setup is tuned for academic / long-form writing in Markdown.

- **Live rendering** in Neovim via `render-markdown.nvim` (LaTeX module
  disabled — no `latex` parser installed).
- **Linting** via `vale`. `make vale` writes a global `~/.vale.ini` with an
  absolute `StylesPath` (`~/.local/share/vale/styles`) and runs `vale sync` to
  download four packages: `proselint`, `write-good`, `Readability`, and `alex`.
  Only `Vale` + `proselint` run globally — the lean baseline for scholarly
  prose (write-good's E-Prime/passive rules, Readability's grade-level caps,
  and alex's terminology checks all misfire on academic history; measured at
  22 of 23 alerts being noise on a typical paragraph). The others are
  per-project opt-ins via `valeinit` (e.g. `Readability` for syllabi).
  `Vale.Spelling` is off — vim's built-in spell owns spelling, `harper_ls`
  owns grammar. A per-project `.vale.ini` overrides the global one.
  A curated **`Academic` vocabulary** (`writing/vale/vocab/Academic/`) is
  tracked in the repo and symlinked into the styles dir by `make vale`
  (`Vocab = Academic`), so proper nouns / domain terms are exempt from any
  spelling or terminology rule and the allowlist syncs across machines.
- **Templates** in `writing/pandoc/`:
  - `metadata.yaml` — Pandoc metadata block (title, author, `bibliography`,
    `geometry`, `fontsize`, `linestretch`). The `bibliography` points at the
    Better CSL JSON export (`Library.json`), not the `.bib` — CSL JSON
    preserves Zotero's archive / archive-location fields that BibTeX drops, so
    archival citations render with repository and box/folder. Better BibTeX
    keeps both `Library.bib` and `Library.json` auto-exported. Copy it next to
    a document and edit:
    ```sh
    cp ~/.dotfiles/writing/pandoc/metadata.yaml .
    ```
  - `defaults.yaml` — the shared Pandoc pipeline (pandoc-crossref → citeproc),
    used by both the nvim `<leader>p` exports and `mdexport`. CSL deliberately
    excluded — a defaults-file `csl` overrides document frontmatter, which
    would silently re-style manuscripts pinned to an older edition.
  - `chicago-notes-bibliography-18th-edition.csl` — the current CMOS (default
    for `newdoc` and `metadata.yaml`).
  - `chicago-notes-bibliography-17th-edition.csl` — kept for in-progress
    manuscripts and journals still on 17e; point a document's `csl:`
    frontmatter at it.
  - `vale-project.ini` — a per-project Vale config (relative `StylesPath`). Copy to a
    project root to override the global `~/.vale.ini`:
    ```sh
    cp ~/.dotfiles/writing/vale/vale-project.ini .
    ```
- **Export** with `<leader>ph` (HTML), `<leader>pp` (PDF), or `<leader>pd`
  (docx) — or `mdexport` from the shell. All:
  - run the shared pipeline from `writing/pandoc/defaults.yaml`
    (pandoc-crossref → citeproc, so cross-references resolve *before*
    citations),
  - `cd` into the document's own directory first, so relative paths in
    `metadata.yaml` (bibliography, CSL) and relative images resolve correctly,
  - auto-add `--metadata-file=metadata.yaml` when a sibling file exists.
- PDF export uses **tectonic** (set in `defaults.yaml`): a self-contained
  XeTeX engine that fetches LaTeX packages on demand — no TeX distribution
  to install, no `tlmgr` package list to maintain. The first PDF build
  downloads what it needs; later builds are offline. Same engine the CV and
  syllabi repos use.

---

### Neovim

A lean, **prose-first** Neovim config built on `lazy.nvim`. The emphasis is
fast startup (almost everything is lazy-loaded), Markdown/Pandoc authoring, and
just enough LSP for the languages used in `bin/` (Lua, Python, Bash) plus
grammar checking in prose (`harper_ls`).

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
        ├── editor.lua       # oil, telescope (+bibtex), treesitter, gitsigns
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
| `<leader>fc`  | Normal | Telescope bibtex — insert `@citekey` **c**itation   |
| `<leader>cf`  | Normal | **C**onform **f**ormat the buffer                   |
| `<leader>ph`  | Normal | **P**andoc export → **H**TML (citeproc + crossref)  |
| `<leader>pp`  | Normal | **P**andoc export → **P**DF (citeproc + crossref)   |
| `<leader>pd`  | Normal | **P**andoc export → **d**ocx (uses `reference.docx`) |
| `<leader>pv`  | Normal | Pre**v**iew in Marked 2 (live-updates on save)      |
| `<CR>`        | Insert | Confirm the selected completion item                |

Pandoc exports run **asynchronously** (`vim.system`) — the editor stays
responsive during slow LaTeX builds; a notification reports success/failure.
The buffer is auto-written before export/preview.

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
- **LSP:** `nvim-lspconfig` for `lua_ls`, `pyright`, `bashls`, `harper_ls`
  (grammar checking in Markdown — vale covers style, vim's built-in spell
  covers spelling, so harper's own SpellCheck linter is disabled), and
  `marksman` (cross-document Markdown navigation: go-to-definition on
  links/headings, link completion, rename across files). Loads only for those
  filetypes.
- **Completion:** `blink.cmp` (lsp + buffer + path + snippets sources, all
  built in — no separate source plugins) with the built-in `vim.snippet`
  expander; loads on `InsertEnter`. Enter confirms only an explicitly
  selected item. `snippets/markdown.json` provides pandoc-crossref snippets
  (`fig`, `tbl`, `eq`, `sec` — label syntax for figures/tables/equations/sections —
  plus `note` for self-numbering inline footnotes, the low-friction form for
  Chicago notes style).
- **Citations:** `telescope-bibtex` (`<leader>fc`) fuzzy-finds the Zotero
  Better BibTeX export (`~/Documents/Library/Library.bib`) and inserts a
  pandoc `@citekey`.
- **Formatting:** `conform.nvim` — `stylua` (Lua), `black` (Python),
  `prettier` (Markdown). Trigger with `<leader>cf`.
- **Linting:** `nvim-lint` runs `vale` on Markdown (read/save) — see
  [Prose and Pandoc](#prose-and-pandoc).

> **Plugin pins:** `lazy-lock.json` is committed so every machine gets the same
> plugin versions. To update all plugins to their latest commits, run `:Lazy update`
> inside Neovim, then commit the resulting `lazy-lock.json` change.

> All LSP servers, formatters, and linters are installed by the Brewfile
> (`lua-language-server`, `pyright`, `bash-language-server`, `harper`,
> `marksman`, `stylua`, `black`, `prettier`, `vale`) — there is no Mason layer.

> **Personal dictionary:** words added with `zg` write to
> `writing/nvim/spell/en.utf-8.add` (`spellfile` is pinned to the config dir),
> so the dictionary is version-controlled and syncs across machines. The
> compiled `.add.spl` binary is regenerated locally and gitignored.

---

### Writing functions and aliases (fish)

The writing-specific subset of `shell/fish/functions/` — autoloaded, call them
like commands. (General-purpose shell functions are listed under [Fish](#fish).)

| Function                | Usage / behavior                                                                      |
|-------------------------|---------------------------------------------------------------------------------------|
| `newdoc <file> [title]` | Create a Markdown file pre-filled with Pandoc metadata and open in Neovim             |
| `mdexport <fmt> <md…>`  | Batch Pandoc export (crossref + citeproc + sibling `metadata.yaml`); mirrors nvim `<leader>p` |
| `words <md…>`           | Prose word count via `pandoc -t plain` (excludes frontmatter/syntax/URLs)             |
| `cite`                  | fzf over the Zotero `.bib`; copies `@citekey` (warns if the export is >30 days stale) |
| `linkcheck [md…]`       | Check links with `lychee` (no args: all `*.md` under the cwd)                         |
| `mdarchive <md…>`       | Snapshot every URL cited in the file(s) to the Wayback Machine (lychee + `waybackup`) |
| `mdimport <docx> [mode]`| Convert returned `.docx` edits to markdown (`--track-changes`: all/accept/reject)     |
| `valeinit`              | Scaffold a per-project `.vale.ini` from `writing/vale/vale-project.ini`               |
| `pdfpages <pdf> <range>`| Extract a page range to a new PDF (`qpdf`)                                            |
| `pdfmerge <out> <in…>`  | Merge PDFs into one (`qpdf`)                                                          |
| `wordfrequency`         | Read stdin, print word counts sorted high→low (great for prose)                       |
| `archgrep <query>`      | Full-text search the OCR'd archival scans (`ripgrep-all`); prints matching page numbers |
| `archcheck`             | List archival PDFs with no OCR text layer (run `ocrmypdf` on those)                    |
| `archverify [--update]` | SHA-256 manifest of the scans; detects corruption / bit-rot                           |
| `archbackup [snapshots]`| `restic` versioned, encrypted snapshot of the archive to an external HD               |
| `citecheck <md…>`       | Validate every `@citekey` in a draft against `Library.json` before export            |
| `zotcheck [--list]`     | Reconcile notes vs Zotero — orphaned citekeys, and items lacking a note                |
| `readnote <key> [--primary]` | Scaffold a reading note for a Zotero citekey (metadata from `Library.json`); closes a `zotcheck` gap |

**Bibliography sources.** Pandoc *rendering* (`newdoc`, `metadata.yaml`) reads
the Better CSL JSON export (`~/Documents/Library/Library.json`), which preserves
Zotero's archive / box-folder fields that BibTeX drops; the citekey *pickers*
(`cite`, telescope-bibtex) stay on `Library.bib` since they parse BibTeX syntax.
Better BibTeX keeps both auto-exported. The Obsidian Pandoc plugins use the same
CMOS 18e CSL, so in-app previews match final output.

**Archive integrity.** `archgrep` / `archcheck` / `archverify` / `archbackup`
operate on `~/Notes/03 Research/Archives` (the Obsidian vault, outside this repo)
— the functions live here, the irreplaceable scans live there.

**Workflow paths.** The personal locations these functions touch (Zotero
library, notes trees, research archives, website repo) are defined once in
`shell/fish/conf.d/paths.fish` (`ZOTERO_LIBRARY_JSON`, `READING_NOTES_DIR`,
`RESEARCH_ARCHIVES_DIR`, …) rather than hardcoded per function. Each is
`set -q`-guarded, so a per-machine `set -Ux` override wins.

**Aliases**

| Alias    | Expands to                                                            |
|----------|-----------------------------------------------------------------------|
| `rgmd`   | `rg -t md` — search only markdown (named to avoid macOS's `mdfind`)   |
| `drafts` | Markdown files modified in the last 7 days (`fd` → `eza`, by mtime)   |
| `marked` | `open -a "Marked 2"` — preview (shell twin of nvim `<leader>pv`)      |

For revision review, `git wdiff` (abbr `gwd`) shows word-level diffs of prose —
see [Git aliases](#git-aliases).

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
| `site <cmd> [args]`     | Website (jaredeberle.org) tasks from anywhere — pure dispatch to `~/git/website/scripts/`: `new`/`images`/`preflight`/`push`/`serve`/`archive`/`sync-hugo`/`csp`/`theme` |
| `acp <message>`         | **a**dd, signed **c**ommit, **p**ush in one step (quotes optional)                    |
| `bb [path]`             | Launch BBEdit; with a dir, open **and** `cd` into it                                  |
| `cdf`                   | `cd` to the directory open in the front Finder window                                 |
| `fuck`                  | Re-run the previous command under `sudo`                                              |
| `gpg-master-import`     | Import the offline GPG master key from USB for editing                                |
| `gpg-master-done`       | Remove master key and reimport machine-specific subkeys only                          |
| `mkd <dir>`             | `mkdir -p` then `cd` into it                                                          |
| `o [paths]`             | `open` the current dir (no args) or the given paths                                   |
| `pman <cmd>`            | Open a man page rendered as a PDF in Preview                                          |

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
most-recent commit. A commit-message template (`git/gitmessage` →
`~/.gitmessage`, via `commit.template`) prefills subject/body guidance for
manual commits.

**Security defaults:** `transfer/fetch/receive.fsckObjects = true` reject
malformed/malicious objects on clone/fetch. `core.hooksPath = ~/.dotfiles/git/hooks`
points every repo at a tracked `pre-commit` hook that runs `gitleaks git --staged`
to block accidental secret commits (the guard for `acp`'s `git add . && git push`).
The hook fails *open* if gitleaks isn't installed (warns, allows) so commits
still work everywhere; `make apps` installs gitleaks. Bypass a false positive
with `git commit --no-verify`. NOTE: a repo that sets its own `core.hooksPath`
(e.g. husky) overrides this, so the scan won't run there.

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
| `git wdiff`   | `diff --word-diff=color` — word-level diff for prose/manuscripts (abbr: `gwd`) |

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
| `org.jaredeberle.resticcheck`     | Sundays 10:00   | `archbackup check` (restic integrity; no-op if the drive is unmounted) |

Installed by `make brewauto`, `make mailsync`, and `make resticcheck`
respectively. Logs: `~/.local/brew_update_logs.txt` (newest run first),
`~/.local/mail_sync_logs.txt`, `~/.local/restic_check_logs.txt`. Trigger a run on demand:

```sh
launchctl kickstart -k gui/$(id -u)/org.jaredeberle.brewupdate
launchctl kickstart -k gui/$(id -u)/org.jaredeberle.mailsync
```

### macOS Services

`make services` (run automatically by `make install`) symlinks every Automator
workflow in `macos/services/` into `~/Library/Services`. All three are browser
integrations that reach into a running browser — they have no terminal
equivalent, which is why they earn a place in an otherwise terminal-only
environment:

| Service                     | Does                                                       |
|-----------------------------|------------------------------------------------------------|
| `Open in Firefox`           | Opens the frontmost Safari tab's URL in Firefox            |
| `md - Links - Firefox Tabs` | Copies all open Firefox tabs as a Markdown reference list  |
| `md - Links - Safari Tabs`  | Copies all open Safari tabs as a Markdown reference list   |

`Open in Firefox` is meant to be bound to a hotkey (System Settings → Keyboard →
Keyboard Shortcuts → Services). Because that hotkey uses Option — which triggers
Firefox's Troubleshoot/safe mode if held during a cold launch — the script only
launches the binary directly (with `MOZ_DISABLE_SAFE_MODE_KEY=1`) when Firefox is
closed; when it's already running it hands the URL off with `open -a Firefox`,
which opens a new tab reliably and skips the startup modifier check entirely. The
cold-start path passes `-new-tab` so the URL isn't swallowed by session restore.

To add another, drop the `.workflow` bundle into `macos/services/` and re-run
`make services`; `make doctor` then verifies the symlink. Restart the target
app (or `killall Finder`) if the Services menu doesn't refresh.

> The rest of the Markdown Service Tools (the `md - *` text transforms) were
> deleted deliberately: macOS Services only fire from a GUI app's right-click
> menu, and this is a Neovim/NeoMutt/Pandoc setup with no GUI text editor — so
> they had nowhere to fire and duplicated `pandoc`/Neovim functionality.

---

## Security

Configs symlinked by `make security`:

- **SSH** (`security/ssh-config`): modern crypto only — hybrid post-quantum key
  exchange first (ML-KEM / sntrup761 + x25519), AEAD-only ciphers (AES-256-GCM
  preferred, ChaCha20-Poly1305 fallback), ETM MACs, `IdentitiesOnly`, agent +
  Keychain integration, strict host-key checking, connection multiplexing for
  Codeberg (`ControlPath ~/.ssh/control/%C`, persisted 10m), no agent/X11
  forwarding, `github-443` fallback for networks that block port 22.
  A key-algorithm floor (`PubkeyAcceptedAlgorithms`/`HostKeyAlgorithms` +
  `RequiredRSASize 3072`) refuses `ssh-rsa`/SHA-1, DSA, and short RSA keys.
  ECDSA P-256 is permitted (alongside Ed25519/RSA-SHA2) because Secure-Enclave
  keys must be P-256 — see SSH key custody below.
- **Pinned host keys** (`security/known_hosts` → `~/.ssh/known_hosts_pinned`):
  GitHub/Codeberg host keys are pre-trusted via a second `UserKnownHostsFile`,
  removing the trust-on-first-use prompt (and its MITM window) on a fresh
  machine. Fingerprints are documented in-file; re-verify against the providers'
  docs and update when they rotate.
- **GPG** (`security/gpg.conf`, `gpg-agent.conf.tmpl`, `dirmngr.conf`, `common.conf`):
  hardened algorithm preferences (AES-256 / SHA-512), strong S2K, `pinentry-mac`,
  `import-minimal`/`export-minimal`, `no-allow-loopback-pinentry`, `use-keyboxd`
  (`common.conf`), privacy-conscious keyserver/dirmngr defaults (LDAP disabled).
  `auto-key-locate local,wkd` omits keyservers so key lookups don't leak the
  queried key ID. Git commit and tag signing uses GPG (`gpg.format = openpgp`) —
  the same key works across GitHub and Codeberg without cross-registering SSH keys.
- **GPG master key management**: `gpg-master-import` / `gpg-master-done` fish
  functions handle the import-edit-cleanup cycle for the offline master key.
  `gpg-master-done` detects the machine (Leia/Ahsoka), reimports only the correct
  machine-specific subkeys, and stages the export inside `~/.gnupg` under
  `umask 077` (never a predictable `/tmp` path).
- **Secret scanning + git integrity** (`git/hooks/pre-commit`, `gitconfig`):
  a global `core.hooksPath` runs `gitleaks` on staged changes before every
  commit, and `*.fsckObjects` reject malformed objects on fetch/clone. See the
  [Git](#git) section.
- **Shell/env hardening** (`shell/fish/conf.d/env.fish`): `umask 077` (owner-only
  by default), `HOMEBREW_NO_INSECURE_REDIRECT`, and a
  `fish_should_add_to_history` filter that keeps space-prefixed and
  secret-bearing command lines out of shell history.
- **Firefox** (`security/betterfox/` submodule + `security/user-overrides.js`):
  `make firefox` concatenates both into a single `user.js` written to the active
  Firefox profile. Personal overrides (Smoothfox scroll tuning, DoH/NextDNS,
  shutdown sanitizing, etc.) live in `user-overrides.js` — Betterfox itself is
  never edited. To update Betterfox: `make betterfox-update`, review the diff,
  then `make firefox`.

### SSH key custody (Secretive)

The `secretive` cask stores SSH keys in the **Secure Enclave**:
non-exportable, hardware-bound, Touch-ID-gated. Keys are generated in the
enclave (you cannot import existing keys) and are per-machine, so each Mac gets
its own key registered with each provider. Because the enclave only supports
NIST P-256, these are ECDSA keys — hence the `PubkeyAcceptedAlgorithms` allowance
above. `env.fish` points `SSH_AUTH_SOCK` at Secretive's socket (guarded on its
existence) so `ssh`, `git`, **and** `ssh-keygen` all use the enclave keys —
the last matters for `ssh-keygen -Y sign` (Codeberg/Forgejo key verification),
which ignores `ssh_config`'s `IdentityAgent`. Per-machine setup steps live in
`security/ssh-config`.

### Optional system hardening (separate targets)

Not part of `make install` — each touches system state and most need `sudo`:

- **`make harden`** (sudo): enables the application firewall + stealth mode,
  automatic macOS security updates / security responses, and opts out of Apple
  diagnostics submission.
- **`make touchid`** (sudo): enables Touch ID for `sudo` via `/etc/pam.d/sudo_local`
  (with `pam_reattach` ahead of `pam_tid` so it works inside tmux).
- **FileVault**: not toggled here (enabling headless is unsafe), but
  `make macos-check` / `make doctor` warn if full-disk encryption is off.
- **Backup integrity**: `archbackup check` runs `restic check` on the encrypted
  research-scan repo; `make resticcheck` schedules it weekly (see [Launchd](#launchd)).

`make macos-check` verifies the `harden`/`touchid`/FileVault state.

---

## Repository Layout

```
.dotfiles/
├── Makefile              # symlink/install targets
├── README.md
├── backup/               # restic-check LaunchAgent plist template
├── bin/                  # scripts on $PATH (brew jobs, ipic, waybackup)
├── security/             # ssh, gpg, dirmngr, firefox configs + pinned known_hosts
│   ├── betterfox/        # Betterfox submodule (upstream user.js — never edited)
│   └── user-overrides.js # personal Firefox prefs appended on top of Betterfox
├── git/                  # gitconfig, gitignore, gitmessage, lazygit.yml
│   └── hooks/            # pre-commit (gitleaks secret scan; via core.hooksPath)
├── homebrew/             # Brewfile + LaunchAgent plist templates
├── macos/                # macOS GUI artifacts
│   └── services/         # Automator workflows symlinked into ~/Library/Services
├── shell/                # all terminal/shell environment configs
│   ├── bat/              # bat pager config
│   ├── fish/             # config.fish, conf.d, functions
│   ├── ghostty/          # terminal emulator config
│   └── tmux.conf         # tmux config
└── writing/              # editor, Pandoc templates, Vale configs, and mail
    ├── nvim/             # Neovim config (see Neovim section); spell/ holds the tracked personal dictionary
    ├── neomutt/          # NeoMutt config (neomuttrc, gpg.rc, colors.rc, mailcap, mbsyncrc, notmuch-config, plist)
    ├── pandoc/           # metadata.yaml, CSL, reference.docx
    └── vale/             # global vale.ini + vale-project.ini template + vocab/ (Academic vocabulary)
```

---

## Credits

Many of these files have been refined over years from sources I've mostly
forgotten — if something here deserves attribution, let me know. The `ipic`
script is originally by [Dr. Drang](https://github.com/drdrang/ipic).
