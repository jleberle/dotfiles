# Maintenance: checks, health, and Makefile targets

When something feels off — a command missing, a config not applying, a fresh
machine acting differently — start here. Two commands cover most situations:

- **`make check`** — every read-only health check at once (symlinks, keys,
  macOS defaults, Homebrew packages, tool binaries). Anything wrong prints a
  `WARNING: ... (run: make <target>)` line that names the fix.
- **`make lint`** — checks the repo's own files for mistakes (shell scripts,
  fish syntax, Python, Lua, and a scan for accidentally committed secrets). Run
  it after editing anything in the repo.

Beyond those two: **`make writing-check`** tests the writing helpers
(`citecheck`, `zotcheck`, `readnote`) against fixture data, and two
macOS-only checks — **`make lint-plists`** (validates the launchd/Automator
files) and **`make nvim-check`** (boots Neovim headless in a throwaway
environment) — normally run in CI, not by hand.

All of these work from any directory via `dots`, e.g. `dots check` (see
[Shell → Functions](shell.md#functions-shellfishfunctions)).

## Check system

### Symlinks, keys, and shell

```sh
make doctor
```

Checks every symlink created by `make install`, plus: SSH keys exist
(`secretive_github.pub`, `secretive_codeberg.pub` — ssh-config points at the
Secretive/Secure Enclave keys, not `id_*`), `~/.ssh`/`~/.gnupg` and the private keys are
owner-only (no group/other access), fish is set as the login shell, the
vale styles directory is populated, a GPG secret key is present, and any
installed launchd agents (mailsync, brewupdate, resticcheck,
decksync) are actually loaded — not just that their plist files exist.

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
Fast way to spot drift after `brew cleanup` or a fresh clone. This also covers
the CLI tools the rest of the setup depends on — delta, vale, pandoc, tectonic,
lazygit, the LSP servers, and the formatters are all Brewfile entries, so the
Brewfile stays the single list to keep current.

### Brewfile drift (reverse direction)

```sh
make brew-drift
```

Lists formulae/casks that are **installed but not in the Brewfile** — the
reverse of `make brew-check`. Catches ad-hoc `brew install`s that would vanish
on the next machine. Informational only (a dry run); deliberately-untracked
items will also appear, so it never removes anything.

## Changing values (where things live)

Most paths that appear in several places are defined once and read everywhere.
A few constants live in multiple config languages that can't share a variable,
so changing them means editing more than one file. The map:

| To change… | Edit |
|---|---|
| **Repo location** | `Makefile` (`DOTFILES`) and `paths.env` (`DOTFILES_DIR`) — plus one that can't use the var: `git/gitconfig` `hooksPath` |
| **Workflow paths** (Zotero library, notes, archives, website) | `paths.env` only |
| **GPG key** (fingerprint / key id) | `git/gitconfig` (`signingkey`), `security/gpg.conf` (`default-key`), `writing/neomutt/gpg.rc` (`pgp_default_key`), `shell/fish/functions/gpg-master-done.fish` (`fingerprint` + subkey ids) |
| **Name / email / GitHub user** | `git/gitconfig` |
| **A new machine** (beyond Leia/Ahsoka) | `gpg-master-done.fish` (`switch $machine`) |
| **Homebrew prefix** | hardcoded `/opt/homebrew` (Apple Silicon) in `Makefile`, `conf.d/env.fish`, `config.fish`, `bin/homebrewupdate.sh`, `bin/mailsync.sh` |

The Nord palette is likewise repeated across `fish_prompt`, the FZF options,
`lazygit.yml`, ghostty, and nvim — different formats with no shared source.

## Makefile targets

Run `make <target>`. There is intentionally **no default** target (`make` alone
just prints a warning) so nothing destructive happens by accident.

| Target             | What it does                                                                                        |
|--------------------|-----------------------------------------------------------------------------------------------------|
| `install`          | Runs `apps git shell security nvim vale neomutt services brewauto` in order, then `doctor`          |
| `chsh`             | Adds fish to `/etc/shells` and sets it as the login shell via `dscl` (requires sudo)                |
| `git`              | Symlinks `gitconfig`/`gitignore`/`gitmessage` + lazygit config; makes the `pre-commit` (gitleaks) and `pre-push` (website preflight) hooks executable |
| `shell`            | Symlinks fish (`shell/fish/`), Ghostty, tmux, and bat configs                                       |
| `security`         | Symlinks SSH config + pinned `known_hosts` + GPG configs; creates `~/.ssh/control` and `~/.gnupg` with safe perms |
| `firefox`          | Detects the default Firefox profile via `installs.ini` and writes `user.js` (Betterfox + overrides) |
| `betterfox-update` | Pulls latest Betterfox upstream into the submodule; re-run `make firefox` afterwards               |
| `apps`             | `brew bundle` against `homebrew/brewfile` (CLIs, casks, fonts, Mac App Store apps)                 |
| `nvim`             | Symlinks the whole `writing/nvim/` dir → `~/.config/nvim`                                           |
| `vale`             | Writes a global `~/.vale.ini` with an absolute `StylesPath`, creates the styles dir, runs `vale sync` |
| `neomutt`          | Symlinks NeoMutt config files into `~/.config/neomutt/`, creates cache dirs, scaffolds `~/.mbsyncrc` and `~/.notmuch-config` from templates if missing |
| `services`         | Symlinks the Automator workflows in `macos/services/` into `~/Library/Services` (run by `make install`; see [Automation → macOS Services](automation.md#macos-services)) |
| `mailsync`         | Installs a launchd agent that runs `mbsync -a && notmuch new` every 5 minutes                      |
| `resticcheck`      | Installs a launchd agent that runs `archbackup check` (restic integrity) weekly; no-op when the backup drive is unmounted |
| `decksync`         | Installs a `WatchPaths` launchd agent that syncs the Keynote lecture decks to the "Slides" flash drive whenever a volume mounts; no-op unless that drive appeared |
| `brewauto`         | Installs a `launchd` agent that updates Homebrew weekly (`homebrewupdate.sh` caps its own log at 1 MB) |
| `macos`            | Writes sensible macOS system defaults (keyboard repeat, Finder, Dock, screenshots, system)          |
| `macos-check`      | Reads every key set by `make macos` plus the security checks (FileVault, firewall, auto-updates, Touch ID) and warns on any missing/wrong |
| `harden`           | **(sudo)** Sets `~` to `0700`, enables the application firewall + stealth mode, automatic macOS security updates, and opts out of Apple diagnostics submission |
| `touchid`          | **(sudo)** Writes `/etc/pam.d/sudo_local` to enable Touch ID for `sudo` (with `pam_reattach` so it works inside tmux) |
| `brew-check`       | Runs `brew bundle check` to verify every Brewfile package is installed                              |
| `brew-drift`       | Lists formulae/casks installed but **not** in the Brewfile (reverse of `brew-check`; dry run)       |
| `lint`             | Runs repo static checks: shellcheck for scripts/hooks, fish syntax checks, `py_compile` for the Python helpers, luacheck for nvim Lua, and a full-history gitleaks scan. Each also runs standalone as `lint-shellcheck`/`lint-fish`/`lint-python`/`lint-luacheck`/`lint-secrets` |
| `lint-plists`      | macOS-only: `plutil -lint` over tracked LaunchAgents and Automator workflow files                    |
| `writing-check`    | Runs fixture-backed smoke tests for the academic-writing helpers (`citecheck`, `zotcheck`, `readnote`) |
| `nvim-check`       | Runs a headless Neovim startup smoke test in a temporary XDG tree                                    |
| `update`           | Updates the non-brew toolchain — Neovim plugins (Lazy sync) and `vale sync`; Homebrew/Betterfox stay on their own paths. Also prints the CI-pinned vs. local gitleaks version, since that pin is bumped by hand |
| `doctor`           | Checks symlinks, SSH keys, key/secret-dir permissions, login shell, vale styles, GPG key, git hooksPath/gitleaks, and that launchd agents are loaded (FileVault is checked by `macos-check`) |
| `check`            | Runs all read-only health checks at once: `doctor` + `macos-check` + `brew-check` |

`harden` and `touchid` are **not** part of `make install` — they touch system
files under `sudo`, so run them deliberately. `resticcheck` is optional and only
useful once `archbackup` is configured (see [Security](security.md)).
