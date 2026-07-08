# Shell: Ghostty, fish, and tmux

The terminal stack, bottom to top: **Ghostty** is the terminal app, **fish**
is the shell running inside it, and **tmux** (optional, per session) splits
one terminal into panes and keeps sessions alive. All three share the Nord
theme.

## Ghostty

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

## Fish

Configured for speed: external tool initializations (`fzf`, `zoxide`) are
**cached to disk** and only regenerated when the binary is newer than the
cache. Autosuggestions, syntax highlighting, and completions are
built into fish, so there are no shell plugins to source or `compinit` to run.

- `conf.d/env.fish` — environment (`EDITOR=nvim`, `PAGER="bat --style=plain"`,
  `MANPAGER="nvim +Man!"`, `BAT_THEME`, `LS_COLORS`, `HOMEBREW_NO_ANALYTICS`,
  `HOMEBREW_NO_ENV_HINTS`), PATH (`~/.dotfiles/bin`, `~/.local/bin`), and the
  Homebrew shellenv.
  `conf.d/*.fish` is auto-sourced for every session.
- `conf.d/paths.fish` — exports the workflow locations from
  [`paths.env`](../paths.env) (Zotero library, notes trees, website repo);
  per-machine `set -Ux` overrides win.
- `conf.d/options.fish` — documents how zsh `setopt`s map to fish defaults and
  disables the startup greeting.
- `conf.d/aliases.fish` — see below.
- `config.fish` — interactive setup: keybindings, fzf, zoxide.
- `functions/` — autoloaded functions (see below).
- `functions/fish_prompt.fish` — native fish prompt: directory (Nord purple),
  git branch (Nord yellow), git status indicators (Nord blue), prompt character
  (green ❯ on success, red on error). No external dependency.

### Shell behavior

- **History:** **shared** across sessions, de-duplicated, and effectively
  unbounded — all by default (no `HISTSIZE`/`SHARE_HISTORY` to configure).
- **Autosuggestions** and **syntax highlighting** are built in (replacing
  `zsh-autosuggestions`/`zsh-syntax-highlighting`), as are man-page-backed
  **completions** (no `compinit`).
- **Directory history** — `prevd`/`nextd` (Alt-←/→) and `cd -` cover the
  `AUTO_PUSHD` workflow; `**` recursive globbing is built in.
- **Gaps vs zsh:** fish has no `AUTO_CD` (use `cd`, or zoxide's `z`), no
  `NO_CLOBBER` (`>` overwrites — use `>>`), and no `HIST_IGNORE_SPACE`.

### Keybindings

| Keys                       | Action                                            |
|----------------------------|---------------------------------------------------|
| `Ctrl-←` / `Ctrl-→`        | Move by word                                      |
| `↑` / `↓`                  | History search seeded by what you've typed        |
| `Ctrl-R`                   | fzf fuzzy history search                          |
| `Ctrl-T`                   | fzf file picker (uses `fd`, `bat` preview)        |
| `Alt-C`                    | fzf `cd` into a subdirectory (`eza` tree preview) |

### zoxide

`z <partial>` jumps to a frecency-ranked directory; `zi` opens an interactive
picker.

### Aliases

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
| `gwd`  | `git wdiff` — word-level diff for prose/manuscripts     |
| `gl`   | `git log --oneline --graph --decorate -20`              |
| `glo`  | `git log --graph --decorate --oneline --all`            |
| `gco`  | `git checkout`                                          |
| `gb`   | `git branch`                                            |
| `grst` | `git restore`                                           |
| `gund` | `git reset --soft HEAD~1` (undo last commit)            |
| `gus`  | `git restore --staged` (unstage)                        |
| `glst` | `git log -1 HEAD` (show last commit)                    |

### Functions (`shell/fish/functions/`)

Autoloaded — call them like commands. (The writing/research functions are
documented in [Writing](writing.md#writing-functions-and-aliases-fish).)

| Function                | Usage / behavior                                                                      |
|-------------------------|---------------------------------------------------------------------------------------|
| `dots <target>`         | Run a dotfiles `make` target from any directory (`dots doctor`, `dots install`, etc.) |
| `site <cmd> [args]`     | Website (jaredeberle.org) tasks from anywhere — pure dispatch to `~/git/website/scripts/`: `new`/`images`/`publish`/`preflight`/`ship`/`serve`/`archive`/`cite-refs`/`to-avif`/`sync-reading`/`newsource`/`newbook`/`finishsource`/`finishbook`. Run `site` with no arguments for usage. See [Writing → Reading workflow](writing.md#reading-workflow-vault--website) |
| `newreading <key> [type]` | `readnote` + `site sync-reading` in one step — see [Writing → Reading workflow](writing.md#reading-workflow-vault--website) |
| `acp <message>`         | **a**dd, signed **c**ommit, **p**ush in one step (quotes optional)                    |
| `bb [path]`             | Launch BBEdit; with a dir, open **and** `cd` into it                                  |
| `cdf`                   | `cd` to the directory open in the front Finder window                                 |
| `depmerge <pr-number>`  | Merge a Dependabot PR locally and push to both remotes — see [Git](git.md)            |
| `fuck`                  | Re-run the previous command under `sudo`                                              |
| `gitup`                 | Run `gitup` over the tracked bookmarks file (`git/gitup-bookmarks`)                   |
| `gpg-master-import`     | Import the offline GPG master key from USB for editing                                |
| `gpg-master-done`       | Remove master key and reimport machine-specific subkeys only                          |
| `mailsync`              | Sync mail on demand (`mbsync -a` + `notmuch new`) — see [Mail](mail.md)               |
| `mkd <dir>`             | `mkdir -p` then `cd` into it                                                          |
| `o [paths]`             | `open` the current dir (no args) or the given paths                                   |
| `pman <cmd>`            | Open a man page rendered as a PDF in Preview                                          |

---

## tmux

**Prefix:** `Ctrl-a` (remapped from the default `Ctrl-b`). Press `Ctrl-a`
twice to send a literal `Ctrl-a` to the underlying program.

### Key bindings

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

### Behavior & options

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
