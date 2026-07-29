# Dotfiles

A macOS-focused, speed-oriented development and **prose-writing** environment.
Everything is symlinked from `~/.dotfiles` via a `Makefile` — the real configs
live in this repo, and the places apps look for them (`~/.config/fish`,
`~/.gitconfig`, …) just point here — so a new machine comes up the same as the
old one. The editor (Neovim), terminal (Ghostty),
multiplexer (tmux), shell (fish), and color theme (**Nord**) are all
wired to work together.

> **Platform:** macOS only, Apple Silicon (Homebrew at `/opt/homebrew`). It uses
> `pbcopy`/`pbpaste`, `launchd`, `osascript`, Automator services, and symlinks
> Ghostty into `~/Library/Application Support`.

**Note**: I had Claude write this up largely so I know where to look when
something breaks or I forget a command. If something doesn't make sense, it's
probably really internal to my system. Feel free to reach out, but all of this
is beyond my abilities to troubleshoot.

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
| NeoMutt   | Follow [docs/mail.md](docs/mail.md) (Bridge password, `~/.mbsyncrc`, Keychain, `make mailsync`) |
| macOS     | Logout and back in for keyboard repeat changes to take full effect                          |

> **Why `~/.dotfiles`?** Every symlink in the `Makefile` is rooted at
> `$(HOME)/.dotfiles`. Cloning anywhere else will break the symlinks.

---

## Daily use

The commands that come up day to day. Everything below works from any
directory; if one of them misbehaves, `make check` (or `dots check`) usually
names the problem and the fix.

**Health and upkeep**

| Command          | Purpose                                                                    |
|------------------|-----------------------------------------------------------------------------|
| `make check`     | All read-only health checks (`doctor` + `macos-check` + `brew-check`)      |
| `make lint`      | Repo static checks (shellcheck, fish syntax, luacheck, gitleaks)            |
| `make update`    | Update the non-brew toolchain (Neovim plugins, TPM, vale styles)            |
| `brewup`         | Update Homebrew now (it also updates itself weekly via launchd)             |
| `dots <target>`  | Run any dotfiles `make` target from anywhere (`dots check`, `dots doctor`)  |

**Writing and research**

| Command                    | Purpose                                                       |
|----------------------------|---------------------------------------------------------------|
| `newdoc <file> [title]`    | New Markdown doc with Pandoc metadata, opened in Neovim       |
| `cite`                     | Fuzzy-pick a citation; copies `@citekey`                      |
| `citecheck <md…>`          | Validate a draft's citekeys against the Zotero library        |
| `newreading <key> [type]`  | Start a source: vault reading note + website ledger entry     |
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

Run `site` with no arguments for the full subcommand list.

---

## Documentation

Deeper documentation lives in [`docs/`](docs/):

| Doc                                      | Covers                                                             |
|------------------------------------------|--------------------------------------------------------------------|
| [docs/writing.md](docs/writing.md)       | Pandoc pipeline, Vale, Neovim config, writing functions, and the reading workflow (Zotero ↔ Obsidian vault ↔ website) |
| [docs/shell.md](docs/shell.md)           | Ghostty, fish (behavior, keybindings, aliases, functions), tmux    |
| [docs/git.md](docs/git.md)               | Git config, signing, hooks, remotes/CI mirror, Dependabot workflow |
| [docs/mail.md](docs/mail.md)             | NeoMutt + Proton Bridge setup, keybindings, background sync        |
| [docs/automation.md](docs/automation.md) | `bin/` scripts, launchd agents, macOS Services                     |
| [docs/security.md](docs/security.md)     | SSH, GPG, Firefox/Betterfox, Secretive, system hardening           |
| [docs/maintenance.md](docs/maintenance.md) | Every check target, the full Makefile reference, where values live |

---

## Repository Layout

```
.dotfiles/
├── Makefile              # symlink/install targets (see docs/maintenance.md)
├── README.md
├── paths.env             # workflow locations (Zotero, notes, website) — single source of truth
├── docs/                 # deeper documentation (see table above)
├── backup/               # restic-check LaunchAgent plist template
├── bin/                  # scripts on $PATH (brew jobs, ipic, waybackup, writing helpers)
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
├── tests/                # writing-check.sh (fixture-backed smoke tests)
└── writing/              # editor, Pandoc templates, Vale configs, and mail
    ├── nvim/             # Neovim config (see docs/writing.md); spell/ holds the tracked personal dictionary
    ├── neomutt/          # NeoMutt config (neomuttrc, gpg.rc, colors.rc, mailcap, mbsyncrc, notmuch-config, plist)
    ├── pandoc/           # metadata.yaml, CSL, reference.docx
    └── vale/             # global vale.ini + vale-project.ini template + vocab/ (Academic vocabulary)
```

---

## Credits

Many of these files have been refined over years from sources I've mostly
forgotten — if something here deserves attribution, let me know. The `ipic`
script is originally by [Dr. Drang](https://github.com/drdrang/ipic).
