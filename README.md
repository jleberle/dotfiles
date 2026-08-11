# Dotfiles

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A macOS-focused, speed-oriented development and **prose-writing** environment.
Everything is symlinked from `~/git/dotfiles` via a `Makefile` — the real configs
live in this repo, and the places apps look for them (`~/.config/fish`,
`~/.gitconfig`, …) just point here — so a new machine comes up the same as the
old one. The editor (Neovim), terminal (Ghostty), multiplexer (tmux), shell
(fish), and color theme (**Nord**) are all wired to work together.

> **Platform:** macOS only, Apple Silicon (Homebrew at `/opt/homebrew`). It uses
> `pbcopy`/`pbpaste`, `launchd`, `osascript`, Automator services, and symlinks
> Ghostty into `~/Library/Application Support`.

**Note**: I had Claude write this up largely so I know where to look when
something breaks or I forget a command. If something doesn't make sense, it's
probably really internal to my system. Feel free to reach out, but all of this
is beyond my abilities to troubleshoot.

This page is the setup guide and the day-one commands. Everything deeper is in
[`docs/`](docs/) — see [the table below](#where-to-go-next).

---

## Setup

```sh
# 1. Install the Xcode command-line tools (gives you git)
xcode-select --install

# 2. Clone to the expected location (~/git/dotfiles is hard-coded in the Makefile)
git clone --recurse-submodules https://github.com/<you>/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles

# 3. Install Homebrew (if needed) and all apps, CLIs, fonts
make apps

# 4. Symlink all configs and install the scheduled jobs
make install

# 5. Apply macOS system defaults (keyboard repeat, Finder, Dock, screenshots)
make macos

# 6. Set fish as the login shell (sudo; open a new terminal afterwards)
make chsh

# 7. Write Firefox user.js (launch Firefox once first, so the profile exists)
make firefox
```

Then finish the per-app setup:

| App       | One-time step                                                                               |
|-----------|---------------------------------------------------------------------------------------------|
| Firefox   | Launch Firefox once to create the profile, then run `make firefox`                          |
| Fish      | Run `make chsh` (requires sudo); open a new terminal afterwards                             |
| Neovim    | Launch `nvim`; `lazy.nvim` bootstraps plugins and Tree-sitter parsers install automatically |
| NeoMutt   | Follow [docs/mail.md](docs/mail.md) (Bridge password, `~/.mbsyncrc`, Keychain, `make mailsync`) |
| macOS     | Log out and back in for keyboard repeat changes to take full effect                         |

Optional, deliberately not part of `make install` because they need `sudo` and
change system state: **`make harden`** (home directory to `0700`, firewall,
automatic security updates) and **`make touchid`** (Touch ID for `sudo`).

> **Why `~/git/dotfiles`?** Every symlink in the `Makefile` is rooted there, and
> so are `git/gitconfig`, `paths.env`, the launchd plists, and the pandoc
> template. Cloning anywhere else breaks them, so every target that writes to
> your machine stops with an explanation instead.

---

## Day one

Everything below works from any directory.

**Finding your way around**

| Command          | Purpose                                                                    |
|------------------|-----------------------------------------------------------------------------|
| `make help`      | Every `make` target, grouped, with one line each                            |
| `site`           | Every website command (run with no arguments)                               |
| `,` in Neovim    | Hold the leader key for a menu of what it can do; `,?` lists everything     |
| `<Tab>`          | Completions for `dots`, `site`, `archbackup`, `archverify`, `docx2md`, `mdexport` |

Any command also takes `--help`.

**Health and upkeep**

| Command          | Purpose                                                                    |
|------------------|-----------------------------------------------------------------------------|
| `make check`     | All read-only health checks (`doctor` + `macos-check` + `brew-check`)      |
| `make lint`      | Repo static checks (shellcheck, fish syntax, Python, Lua, secrets)         |
| `make update`    | Update the non-brew toolchain (Neovim plugins, Vale styles)                |
| `brewup`         | Update Homebrew now (it also updates itself weekly)                        |
| `dots <target>`  | Run any dotfiles `make` target from anywhere (`dots check`, `dots doctor`) |

When something feels wrong, `make check` names the problem and the fix.

**Writing and research**

| Command                    | Purpose                                                       |
|----------------------------|---------------------------------------------------------------|
| `newdoc <file> [title]`    | New Markdown doc with Pandoc metadata, opened in Neovim       |
| `newmeta`                  | Write a `metadata.yaml` for a folder of documents             |
| `cite`                     | Fuzzy-pick a citation; copies `@citekey`                      |
| `citecheck <md…>`          | Check a draft's citekeys against the Zotero library           |
| `readnote <key>`           | Scaffold a vault reading note from a Zotero citekey           |
| `zotcheck [--list]`        | Reconcile reading/research notes against Zotero               |
| `mdexport <fmt> <md…>`     | Pandoc export (crossref + citeproc) from the shell            |

**Website (jaredeberle.org)**

| Command                     | Purpose                                                     |
|-----------------------------|--------------------------------------------------------------|
| `site new <type> [title]`   | Create a draft post                                          |
| `site serve`                | Local Hugo server with drafts                                |
| `site preflight`            | Build + CSP + reference gate                                 |
| `site ship [message]`       | Preflight, commit, push (deploys)                            |
| `site finishsource [slug]`  | Mark a reading-ledger source finished (syncs the vault note) |

---

## Where to go next

| Doc                                      | Covers                                                             |
|------------------------------------------|--------------------------------------------------------------------|
| [docs/writing.md](docs/writing.md)       | Pandoc pipeline, Vale, Neovim, the writing functions, and the reading workflow (Zotero ↔ Obsidian ↔ website) |
| [docs/shell.md](docs/shell.md)           | Ghostty, fish (behavior, keybindings, aliases, functions), tmux    |
| [docs/git.md](docs/git.md)               | Git config, signing, hooks, remotes/CI, Dependabot workflow        |
| [docs/mail.md](docs/mail.md)             | NeoMutt + Proton Bridge setup, keybindings, background sync        |
| [docs/automation.md](docs/automation.md) | `bin/` scripts, launchd agents, macOS Services                     |
| [docs/security.md](docs/security.md)     | SSH, GPG, Firefox/Betterfox, Secretive, system hardening           |
| [docs/maintenance.md](docs/maintenance.md) | Every check and `make` target, the repo layout, where values live |

[CHANGELOG.md](CHANGELOG.md) has what changed and when.

---

## Credits

Many of these files have been refined over years from sources I've mostly
forgotten — if something here deserves attribution, let me know. The `ipic`
script is originally by [Dr. Drang](https://github.com/drdrang/ipic).
