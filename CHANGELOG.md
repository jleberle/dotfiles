# Changelog

All notable changes to this dotfiles repo. Grouped by milestone rather than
individual commit — the git log has the full detail. Entries from the
2026-05-29–2026-07-08 rewrite are consolidated by theme rather than by day;
everything since is one entry per real milestone.

---

## 2026-08-10 — Audit follow-up: uniform guards, fewer moving parts

- **`bin/homebrewlogclean.sh` and its launchd agent are gone.**
  `homebrewupdate.sh` now caps its own log at 1 MB instead, the way
  `mailsync.sh` already did. That removed a script, a plist, a `make brewauto`
  install step, a shellcheck entry, a `make doctor` check and two docs rows —
  all to delete one file on the first Monday of the month.
  **Action required on machines that already have the agent installed:** it
  keeps running until you remove it —
  `launchctl bootout gui/$(id -u)/org.jaredeberle.brewlogclean` then
  `rm ~/Library/LaunchAgents/org.jaredeberle.brewlogclean.plist`.
  The semantics change from "wiped monthly" to "capped at 1 MB", so the log
  can no longer be emptied just before the run you wanted to read.
- **Two private helpers replace ~14 hand-written guard blocks.**
  `__require` (missing tools) and `__need_path` (missing files and folders)
  now back every such check. Dependency handling in particular used to be a
  coin flip — six functions explained themselves, seven emitted a bare
  `Unknown command`. `__need_path` also distinguishes "not configured" from
  "configured but missing", which need opposite fixes.
- **Lint file lists are globbed, not hand-maintained.** Adding `bin/foo.sh` or
  `bin/foo.py` used to leave it silently unlinted with CI still green.
- **`make services` no longer `rm -rf`s** a real file that shares a name with a
  repo workflow; it skips and says what to move.
- **`acp` and `linkcheck` confirm before the runaway case** — a large
  `git add .` and a whole-tree link check respectively. Both take `--yes`.
- **`~/.gnupg/gpg-agent.conf` says it is generated** in its own header;
  `make security` has always overwritten it, discarding hand edits silently.
- The Makefile now refuses to run from anywhere but `~/git/dotfiles`, and
  several doc rows that disagreed with the code were corrected — notably
  `pubkey-github`, which documented `id_github.pub` while both the alias and
  ssh-config use the Secretive key.

---

## 2026-07-31 — GitHub is now the sole, public remote; Codeberg archived

- Codeberg is archived. GitHub (`jleberle/dotfiles`) is now the sole,
  public, canonical remote, replacing the former Codeberg-canonical /
  private-GitHub-CI-mirror split. `origin` now carries a single fetch/push
  URL instead of one fetch + two push URLs.
- `depmerge <pr-number>` dropped its Codeberg sync step: it fast-forwards
  `main` from GitHub, rebases and watches the PR's checks, then
  fast-forwards and pushes back to GitHub only.
- `docs/git.md`, `docs/security.md`, and the README clone command updated to
  match. `ci.yml` needed no changes for the public repo — SHA-pinned
  actions, `contents: read`-only permissions, and plain `pull_request` (never
  `pull_request_target`) were already safe for fork PRs.

---

## 2026-07-31 — Audit follow-ups: close lint gaps, drop TPM

- `git/hooks/pre-push` joined `SHELLCHECK_FILES`, `make git`'s `chmod`, and
  `docs/git.md`. It had landed outside all three.
- New `make lint-python` (also a CI step): `py_compile` over the five Python
  helpers. Stdlib-only, so it adds no dependency; `-X pycache_prefix` keeps the
  `.pyc` files out of the repo.
- **Removed TPM.** The Nord theme was the only plugin, and upstream
  (`arcticicestudio/nord-tmux`) is archived, so its ~20 `set` lines are now
  vendored into `shell/tmux.conf`. This drops an unpinned `git clone` from
  `make shell`, a plugin-update step from `make update`, and the TPM check from
  `make doctor`. It also fixes a latent bug: `~/.tmux/plugins/tmux` still held
  the old Catppuccin checkout, so TPM had never actually fetched the
  `nordtheme/tmux` the config asked for and was loading both themes.
  `status-interval` now stays at the 5s the config asks for instead of being
  reset to 1s by the plugin.
- `make update` now prints the CI-pinned gitleaks version next to the local
  one, with bump instructions — the version and its checksum in `ci.yml` are
  updated by hand and had no reminder.
- **Dropped `mole`** from the Brewfile. Not for anything it did wrong, but for
  what it is: a tool with its own update channel (`mo update`, including
  `--nightly` main-branch builds) is structurally incompatible with a repo
  whose dependency model assumes Homebrew is the only thing installing
  software — `brew-check`, `brew-drift`, and the weekly `brewupdate` agent all
  see through it. Its `mo touchid` also writes the same
  `/etc/pam.d/sudo_local` that `make touchid` owns, and would drop the
  `pam_reattach` line that makes Touch ID work in tmux, in a way
  `make macos-check` could not detect (that check only greps for `pam_tid.so`).
  Actual use was one invocation in a month, clearing regenerable caches and the
  system logs you want when debugging a panic.
- **Re-enabled WebAuthn** in `security/user-overrides.js`
  (`security.webauth.webauthn` false → true). Disabling it sat with the
  autofill prefs under "let Bitwarden handle credentials," but Bitwarden is a
  passkey *provider* and implements passkeys through that API — so the pref was
  breaking a Bitwarden feature, blocking hardware keys as 2FA, and giving up
  origin-bound phishing resistance, in exchange for closing a surface that
  needs a user gesture and can't enumerate authenticators. Betterfox ships the
  pref commented out. Written as an explicit `true` rather than deleted,
  because removing a pref from `user.js` leaves the old value in an existing
  profile's `prefs.js`.

---

## 2026-07-08 — Wire the reading workflow end to end, split docs from README

- `newreading <citekey> [book|article] [--primary]` — runs `readnote` (vault
  note from Zotero), then `site sync-reading` (website reading-ledger entry),
  so starting a Zotero-backed source is one command.
- `site` gained subcommands for the rest of the website scripts (`ship`,
  `cite-refs`, `to-avif`, `sync-reading`, `newsource`/`newbook`,
  `finishsource`/`finishbook`); dropped `site csp`/`sync-hugo`/`push` in favor
  of running those scripts directly or via `ship`.
- README split: the ~1,000-line file became a short daily-setup page, with
  the deep documentation broken out into `docs/*.md` by topic.
- `make macos`/`make macos-check` unified onto one `MACOS_DEFAULTS` table
  (`domain|key|type|value`) instead of two hand-mirrored recipes.

---

## 2026-06-26 — CI permissions, path-parser dedup, writing-check refactor

- Dropped the scheduled-CI issue-reporter job — it was the only thing
  requiring `issues: write`; CI now only needs `contents: read`.
- Removed the duplicate `paths.env` parser from `paths.lua` — Neovim now just
  reads the env vars `paths.fish` already exported instead of re-parsing the
  file itself.
- Moved `citecheck`/`zotcheck`/`readnote` logic out of `python3 -c` heredocs
  into standalone `bin/*.py` scripts; the fish functions became thin wrappers
  that validate args/env and invoke them.

---

## 2026-06-23–24 — CI migration to GitHub Actions; writing-workflow hardening

CI moved twice in three days: Forgejo Actions (configured but never
executed — Codeberg has no shared runners) → Woodpecker (ran, but the only
consumer) → **GitHub Actions** on a private mirror (hosted Linux + macOS
runners; Codeberg stays the public canonical repo).

- Split lint into four jobs (`shellcheck`, fish syntax, `luacheck`, secrets)
  so one failing check doesn't bury the others in a combined log; added
  macOS-native checks (`lint-plists`, `nvim-check`) only GitHub's macOS
  runners can do.
- Added Dependabot (Actions + monthly Betterfox bump) and `depmerge
  <pr-number>` to fast-forward Dependabot PRs across the Codeberg-canonical /
  GitHub-mirror split.
- Added `make writing-check` — fixture-backed tests for `citecheck`,
  `zotcheck`, `readnote`. Caught two real bugs in the process: `citecheck`
  wasn't validating suppressed-author `-@citekey` citations, and `zotcheck`
  only checked the top level of the note tree instead of recursing.

---

## 2026-06-22 — Full audit pass: bug hunt, platform commitment, Makefile dedup

A single intensive pass: exercised every function with edge cases, ran
`shellcheck`/`luacheck` clean, and did a `make install` ordering + doc-table
accuracy sweep.

**Fixed**
- Fresh-machine `make apps`: the official Homebrew installer doesn't add
  `brew` to the *current* process PATH, so the next recipe line failed on a
  truly clean machine. Now calls `$(HOMEBREW_PREFIX)/bin/brew` directly.
- `words`: piping through `pandoc | wc -w | string trim` meant the
  pipeline's reported status was always `string trim`'s (0), so a failed
  pandoc run silently reported 0 words instead of erroring.
- `wordfrequency`: a leading/trailing delimiter made `awk` emit a spurious
  empty "word".
- `newdoc "Quoted Title"`: `string join` returns non-zero for a single-element
  list, so the `... or echo "Untitled"` fallback fired *in addition to* the
  real title — every frontmatter field after it shifted by one.
- `make doctor`: false positive on `core.hooksPath` (compared the tilde form
  git actually stores against an absolute-path string).
- macOS 26 (Tahoe) false warnings in `make macos-check`: the stealth-mode
  grep looked for `"enabled"` but Tahoe prints `"...is on"`; the auto-update
  check read a legacy key Tahoe no longer populates.

**Changed**
- Committed to macOS / Apple Silicon only — dropped the Linux and Intel
  Homebrew-prefix fallbacks across `env.fish`, `homebrewupdate.sh`,
  `mailsync.sh`, and the Makefile.
- Centralized the repo path (`DOTFILES := $(HOME)/.dotfiles`, one
  `DOTFILES_DIR` fish var) — replaced ~45 literal path occurrences.
- `make check` — one target for every read-only health check.
- Deduped the LaunchAgent install dance (template → lint → bootout →
  bootstrap) into one `install_agent` canned recipe used by `brewauto`,
  `mailsync`, and `resticcheck`.

**Removed** unused Brewfile fonts and the `fn` function (redundant with
`fd`-backed `findf`/`findd`). **Added** `.gitleaks.toml` to allowlist the
public GPG fingerprint (the one legitimate false positive in a full-history
scan) and `shellcheck` itself to the Brewfile (referenced by CI but never
actually installed locally).

---

## 2026-06-21 — Reading-note scaffolder, `make update`, centralized paths

- `readnote <citekey> [--primary]` — scaffolds a reading note from the Zotero
  CSL JSON export, closing the loop `zotcheck` needs (an item with no note).
  Refuses unknown citekeys and won't clobber an existing note.
- `make update` — one command for the non-Homebrew toolchain (Neovim plugins,
  tmux TPM, `vale sync`); Homebrew and Betterfox stay on their own
  (review-gated) paths.
- Centralized workflow paths (Zotero library, notes trees, research
  archives, website repo) that several functions had hardcoded independently
  into `conf.d/paths.fish` as `set -q`-guarded vars.

## 2026-06-21 — Security hardening: secret scanning, key custody, backups

- **Secret scanning**: a tracked `git/hooks/pre-commit` hook runs `gitleaks
  git --staged` before every commit (fails *open* if gitleaks isn't
  installed — warns, allows).
- **`make harden`/`make touchid`** (sudo, excluded from `make install`):
  firewall + stealth mode, automatic security updates, Apple diagnostics
  opt-out; Touch ID for `sudo` via `pam_reattach` + `pam_tid`.
- **FileVault check** in `make doctor`/`macos-check` — warned, not toggled
  automatically (headless enable is unsafe).
- **Pinned SSH host keys** (`known_hosts_pinned`) — removes the
  trust-on-first-use window for GitHub/Codeberg on a fresh machine.
- **SSH key custody via Secretive** (Secure Enclave) — `SSH_AUTH_SOCK`
  routed to Secretive's socket so `ssh`/`git`/`ssh-keygen` all use enclave
  keys.
- **Backup integrity**: `archbackup check` runs `restic check` on the
  encrypted research-scan repo; `make resticcheck` schedules it weekly.
- Shell hardening: `umask 077`, `HOMEBREW_NO_INSECURE_REDIRECT`, a
  `fish_should_add_to_history` filter dropping space-prefixed/secret-bearing
  lines.
- **Fixed**: `gpg-master-done` staged exported subkeys under `~/.gnupg`
  (mode 0700) instead of a predictable, world-readable `/tmp` path. `ipic`
  now `html.escape`s API-supplied URLs (a stray quote could break out of an
  attribute). `fuck` now shows the command and asks for confirmation before
  re-running it under `sudo`.

---

## 2026-06-16 — macOS Services; drop stale zsh submodules

- `macos/services/` + `make services` — version-controls three browser
  integrations with no terminal equivalent: `Open in Firefox`, and Markdown
  reference-list copiers for open Firefox/Safari tabs.
- Deleted the other ~36 Markdown Service Tools — macOS Services only fire
  from a GUI right-click menu, and this is a terminal-editor setup with
  nothing for them to act on (one, `HTML to Markdown`, was already broken:
  it embedded a Python-2-only script).
- Purged orphaned `zsh/submodules/*` git config entries left over from the
  pre-fish era.

---

## 2026-06-15 — Zotero/Obsidian integration: CSL JSON, OCR'd archive search

- Citation rendering switched to the Better CSL JSON export (preserves
  Zotero's archive/box/folder fields that the BibTeX translator drops); the
  citekey pickers (`cite`, telescope-bibtex) stay on the `.bib` export since
  they can't parse CSL JSON.
- Research-workflow functions over the OCR'd archival-scan tree: `archgrep`
  (full-text search via ripgrep-all), `archverify` (SHA-256 manifest),
  `archbackup` (restic encrypted snapshots), `archcheck` (flags PDFs missing
  an OCR layer), `citecheck`, `zotcheck`.
- Unified on one CSL stylesheet (CMOS 18e) across pandoc and the Obsidian
  plugins, so in-app previews match final output.

---

## 2026-06-14 — Cross-machine sync, drift checks, markdown LSP

- Neovim spellfile and the Vale `Academic` vocabulary are now tracked in the
  repo, so words/terms added on one machine sync to the others.
- `marksman` markdown LSP for cross-document link/heading navigation.
- `make doctor` now checks that launchd agents are actually *loaded*, not
  just that the plist exists (catches silent sync failures after a macOS
  upgrade). `make brew-drift` lists installed-but-untracked packages.
- `.editorconfig` and a Git commit-message template added.

---

## 2026-06-11 — Academic history workflow: CMOS 18, shared pandoc pipeline

- Pandoc PDF export switched to tectonic (self-contained XeTeX); BasicTeX
  dropped once nothing else needed it.
- `site` fish function — dispatches every website-repo script from any
  directory.
- Added CMOS 18th-edition CSL as the new default (17th kept for in-progress
  manuscripts, set per-document); `writing/pandoc/defaults.yaml` as the one
  shared pandoc pipeline for both nvim and `mdexport` — deliberately
  excludes `csl:`/`bibliography:`, since a defaults-file value silently
  overrides document frontmatter.
- `mdarchive` (snapshot every URL in a draft to the Wayback Machine via
  `waybackup`) and `mdimport` (docx → markdown round-trip via
  `--track-changes`).

---

## 2026-06-10 — Future-proofing audit: post-quantum SSH, Vale trim, bootstrap

- SSH key exchange now prefers hybrid post-quantum algorithms
  (`mlkem768x25519-sha256`, `sntrup761x25519-sha512`) — the old pinned list
  silently excluded current OpenSSH defaults. Ciphers reordered AES-256-GCM
  first (unaffected by the Terrapin downgrade attack, CVE-2023-48795).
- Global Vale config trimmed to `Vale, proselint` — measured 23 alerts down
  to 1 actionable one on a sample paragraph; the other three packages (write-
  good, Readability, alex) moved to per-project opt-in.
- Added the markdown/academic-writing function set: `mdexport`, `words`,
  `cite`, `linkcheck`, `valeinit`, `pdfpages`/`pdfmerge`; nvim gained async
  Pandoc export (`vim.system`, no more editor freeze during LaTeX builds),
  `telescope-bibtex.nvim`, and `harper_ls` for grammar.
- Completion migrated `nvim-cmp` → `blink.cmp` (upstream-frozen vs.
  actively maintained; 4 plugins collapsed to 1).
- **Fixed**: `bin/ipic` was emitting curly quotes in a `<meta charset>` tag
  (invalid attribute, broke the UTF-8 rendering the script exists to
  provide); `make mailsync` failed on a fresh account (`LaunchAgents` dir
  never created); fish startup no longer errors without Homebrew/fzf/zoxide.

---

## 2026-06-09 — mailbox.org migration, mbsync + notmuch, background sync

Migrated mail from iCloud to mailbox.org (via `imapsync`), replacing Apple
Mail with NeoMutt + local Maildir sync.

- `bin/mailsync.sh` (`mbsync -a && notmuch new`, timestamped logging) run
  every 5 minutes via a new `make mailsync` LaunchAgent.
- `make neomutt` scaffolds `~/.mbsyncrc`/`~/.notmuch-config` from templates
  on first run; `make doctor` checks both plus the LaunchAgent.
- Assorted mbsync/notmuch correctness fixes: `SSLType` → `TLSType`, Keychain
  service names disambiguated from Apple Mail's OAuth entries,
  `%`-containing passwords quoted, notmuch's `database.path` needs an
  absolute path (no `~` expansion).

---

## 2026-06-08 — NeoMutt integration; repo restructure; Betterfox; macOS defaults

The single biggest day of infrastructure work in the repo's history.

- **NeoMutt**: full config (`neomuttrc`, GPGME-backed `gpg.rc`, Nord
  `colors.rc`, `mailcap` with macOS `textutil`/Firefox handlers); `make
  neomutt` symlinks it all and stubs an account file with a reminder.
- **Repo restructure**: six top-level directories replacing the old ad hoc
  layout (`fish/`+`ghostty/`→`shell/`; `general/`→`security/`+
  `writing/vale/`; `templates/`→`writing/pandoc/`; `nvim/`→`writing/nvim/`;
  `launchd/`→`homebrew/`). Makefile targets collapsed 12→9 to match.
- **`make macos`**: keyboard repeat, Finder, Dock, screenshot, and
  smart-quote/dash defaults, applied idempotently.
- **Betterfox**: tracked as a git submodule; `make firefox` concatenates it
  with personal `user-overrides.js` into the active profile's `user.js`.
- **`make chsh`**: sets fish as the login shell via `dscl` (idempotent,
  sudo).
- Fixed the Homebrew update log so the newest run prepends to the top of
  the file instead of appending to the bottom.

---

## 2026-06-06 — Nord theme everywhere; SSH/GPG hardening round 1

- Switched every themed tool (Ghostty, Neovim, tmux, bat, delta, fzf) from
  Catppuccin Mocha to Nord; replaced the Starship prompt with a native
  `fish_prompt` (identical output, no external dependency).
- Trimmed the Brewfile: `mole` added; nine unused packages removed
  (`ffmpeg`, `exiftool`, `git-lfs`, `gibo`, `wget`, `rbenv`, `pipx`, `pyenv`,
  `starship`, among others) plus Homebrew telemetry/hint env vars disabled.
- **SSH**: dedicated key per host (`id_github`, `id_codeberg`) with a
  port-443 fallback host for networks blocking port 22.
- **GPG**: commit signing switched from SSH back to GPG; `gpg-master-import`/
  `gpg-master-done` functions manage the offline-master-key → per-machine-
  subkey workflow; `no-allow-loopback-pinentry` requires physical pinentry.

---

## 2026-06-01 — Audit fixes; Go/MacTeX removal; Vale packages

- Go toolchain removed entirely (Brewfile + Neovim LSP/treesitter) — no
  project in active use needed it.
- `mactex` (17 GB) replaced with `basictex` (~100 MB) plus the specific
  `tlmgr` packages the CV/syllabus templates need.
- Vale gained `proselint`/`write-good`/`Readability`/`alex` as its package
  set (previously running with none), with `vale sync` wired into `make
  vale`.
- Guard/hardening pass: macOS-only functions (`cdf`, `pman`, `o`, and
  several aliases) now check `uname` and fail cleanly on Linux; `make
  brewauto` lints its generated plists before loading them; `gpg-agent.conf`
  became a `.tmpl` generated per-machine instead of a static tracked file.

---

## 2026-05-31 — Improvements & forward compatibility

- `newdoc` — bootstrap a Markdown file with the Pandoc metadata template.
- `make doctor` — first version, verifying expected symlinks.
- Forgejo Actions CI added (shellcheck, fish syntax, luacheck) — later found
  to never actually run (no Codeberg shared runners) and replaced (see
  2026-06-23–24).
- Assorted future-proofing: `vim.uv` (Neovim 0.11+ deprecation fix),
  `$HOMEBREW_PREFIX` instead of hardcoded `/opt/homebrew`, tmux
  `terminal-features` consolidation, git aliases converted to visible-
  expansion `abbr`s.

---

## 2026-05-29–30 — Full rewrite: zsh → fish, unified theme

The repo's biggest single rewrite: every zsh file removed and replaced with
fish from scratch, alongside a full Neovim rebuild.

- Fish config from scratch (`config.fish`, `conf.d/`, `functions/`); Starship
  prompt in Catppuccin Mocha; fzf/zoxide/starship init cached to disk.
- Neovim rebuilt on `lazy.nvim`: Catppuccin, Telescope, nvim-treesitter
  (main branch), nvim-cmp, nvim-lspconfig, conform.nvim, nvim-lint (Vale),
  render-markdown, zen-mode/twilight, mini.nvim, oil.nvim, gitsigns,
  lualine.
- Pandoc export keymaps with automatic `metadata.yaml` detection;
  `templates/` added (metadata, per-project Vale config, CMOS 17e CSL).
- Ghostty + tmux configs added, both Catppuccin Mocha; SSH hardened
  (curve25519/chacha20 only, multiplexing, no agent/X11 forwarding).
- Weekly Homebrew update + monthly log-rotation LaunchAgents.
- Removed: all zsh config, zsh4humans, Zim, Powerlevel10k, the old
  LazyVim-based Neovim config.

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
