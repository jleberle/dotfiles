# Changelog

What changed, in broad strokes, newest first. Grouped by milestone rather than
by commit.

This file is deliberately shallow: it tells you *what* changed and *when*, not
why or how. The reasoning lives in comments next to the code it explains, and
the working detail lives in [`docs/`](docs/). `git log` has everything else.

Anything needing action on a machine that is already set up is marked
**Action required**.

---

## 2026-08-11 — Second audit pass: Neovim, pandoc, mail

- Mail sync reports failures. It kept no exit status at all, so `mbsync`
  breaking looked exactly like no new mail. Now notifies when sync starts
  failing and when it recovers.
- Pandoc exports no longer claim success when a citation didn't resolve —
  pandoc exits 0 for those and writes `smith2020?` into the document.
- `metadata.yaml` became a template rendered by the new `newmeta` command.
  Copied by hand it could not work: pandoc doesn't expand `~` in metadata, and
  its date was hardcoded.
- Neovim got `which-key` — press `,` and wait, or `,?` for everything.
- The backup-integrity log is timestamped. Smaller fixes to `valeinit`,
  `gitup`, `mdexport`, `make doctor`, `j`/`k` with a count, and the `lazy.nvim`
  bootstrap message when you're offline.

## 2026-08-11 — `umask 077` scoped to what it's good at

- `make harden` sets `~` to `0700`. That, not a umask, is what keeps other
  local accounts out, and you can see it with `ls -ld ~`.
- Homebrew installs at `umask 022` again. It had inherited `077` from the shell
  and was installing world-readable software owner-only.
  **Action required:** existing drift isn't repaired automatically.
  `make brew-check` reports it and prints the fix.
- The umask stays for what it does well: files that leave the machine carrying
  their permissions (GPG key on USB, restic snapshots, synced decks).

## 2026-08-11 — Naming conventions, written down

Four rules now hold everywhere; see [docs/shell.md](docs/shell.md#conventions).

- `archcheck` → `archocr`. The old name is a stub pointing at the new one;
  delete `shell/fish/functions/archcheck.fish` once the new name is habit.
- Finding something always means exit non-zero. `zotcheck` was the outlier.
- `archverify --update` → `archverify update`. Words pick an action, flags
  modify one. The old flag still works.
- One error format: `name: what went wrong`, then the fix indented under it.
- `test` operands quoted in 22 more places.

## 2026-08-10 — Uniform guards, fewer moving parts

- Deleted `homebrewlogclean.sh` and its launchd agent; `homebrewupdate.sh` caps
  its own log instead.
  **Action required** where the agent is installed:
  `launchctl bootout gui/$(id -u)/org.jaredeberle.brewlogclean`, then
  `rm ~/Library/LaunchAgents/org.jaredeberle.brewlogclean.plist`.
- `__require` and `__need_path` replaced ~14 hand-written guard blocks, so
  missing tools and missing paths report the same way everywhere.
- Lint file lists are globbed, not hand-maintained — a new script can no longer
  go silently unlinted.
- `make services` no longer deletes a real file that shares a workflow's name.
- `acp` and `linkcheck` confirm before the runaway case; both take `--yes`.
- `make` targets that write to the machine refuse to run from the wrong
  directory. Read-only lints and checks still run anywhere.

## 2026-07-31 — GitHub is the sole public remote

- Codeberg archived; `jleberle/dotfiles` on GitHub is now canonical, replacing
  the old canonical/mirror split. `depmerge` dropped its Codeberg sync step.

## 2026-07-31 — Lint gaps, TPM removed

- `make lint-python` added (stdlib `py_compile`, also a CI step).
- Removed TPM. Its one plugin was archived upstream, so the Nord theme is
  vendored into `shell/tmux.conf` — dropping an unpinned `git clone` from
  `make shell` and fixing a stale checkout that had been loading two themes.
- Dropped `mole` from the Brewfile: a tool with its own update channel doesn't
  fit a repo where Homebrew is assumed to be the only installer.
- Re-enabled WebAuthn in the Firefox overrides — disabling it was breaking
  Bitwarden passkeys and hardware-key 2FA.
- `make update` prints the CI-pinned gitleaks version next to the local one.

## 2026-07-08 — Reading workflow end to end; docs split out

- `newreading <citekey>` creates the vault note and the website ledger entry in
  one step; `site` gained subcommands for the rest of the website scripts.
- The ~1,000-line README became a short setup guide plus `docs/*.md` by topic.
- `make macos` and `make macos-check` unified onto one table.

## 2026-06-26 — CI permissions, dedup

- CI needs only `contents: read` now.
- Neovim reads the env vars fish exports instead of re-parsing `paths.env`.
- `citecheck`/`zotcheck`/`readnote` logic moved from heredocs into `bin/*.py`.

## 2026-06-23–24 — CI on GitHub Actions

CI moved twice in three days — Forgejo Actions (never ran: no Codeberg
runners) → Woodpecker → GitHub Actions.

- Lint split into separate jobs so one failure doesn't bury the others; macOS
  runners added for plist and Neovim checks.
- Dependabot added, plus `depmerge <pr-number>` to merge its PRs locally.
- `make writing-check` added — fixture-backed tests that immediately caught two
  real bugs (`citecheck` ignored `-@citekey`; `zotcheck` didn't recurse).

## 2026-06-22 — Full audit pass

Exercised every function with edge cases and swept the Makefile and doc tables.

- Fixed: fresh-machine `make apps` (brew not yet on PATH); `words` reporting 0
  instead of erroring; `wordfrequency` emitting an empty word; `newdoc` with a
  quoted title shifting every frontmatter field; two `make doctor` false
  positives; two more from macOS 26 wording changes.
- Committed to macOS / Apple Silicon only — dropped the Linux and Intel
  fallbacks.
- Centralized the repo path (~45 literal occurrences), added `make check`, and
  deduped the LaunchAgent install dance into one canned recipe.

## 2026-06-21 — Security hardening

- Secret scanning on every commit via a tracked `pre-commit` hook.
- `make harden` / `make touchid` (sudo, not part of `make install`): firewall,
  automatic security updates, diagnostics opt-out, Touch ID for `sudo`.
- SSH keys moved into the Secure Enclave via Secretive; host keys pinned;
  FileVault checked but never toggled automatically.
- `archbackup check` verifies the encrypted research-scan repo;
  `make resticcheck` schedules it weekly.
- Shell hardening: `umask 077`, no insecure Homebrew redirects, and a history
  filter for secret-bearing command lines.

## 2026-06-21 — Reading notes, `make update`, centralized paths

- `readnote <citekey>` scaffolds a reading note from Zotero, closing the gap
  `zotcheck` reports.
- `make update` for the non-Homebrew toolchain.
- Workflow paths centralized into `paths.env` instead of being hardcoded per
  function.

## 2026-06-16 — macOS Services

- `make services` version-controls three browser integrations with no terminal
  equivalent; the other ~36 Markdown Service Tools were deleted as unusable in
  a terminal-editor setup.

## 2026-06-15 — Zotero / Obsidian integration

- Citation rendering moved to the Better CSL JSON export, which preserves the
  archive and box/folder fields BibTeX drops. The citekey pickers stay on
  `.bib`.
- Added the archival-scan functions: `archgrep`, `archverify`, `archbackup`,
  `archocr`, `citecheck`, `zotcheck`.
- One CSL stylesheet (CMOS 18e) across pandoc and Obsidian, so previews match
  output.

## 2026-06-14 — Cross-machine sync

- Neovim's spellfile and Vale's `Academic` vocabulary are tracked, so words
  added on one machine reach the others.
- `marksman` markdown LSP; `make doctor` now checks agents are *loaded*, not
  just installed; `make brew-drift` lists untracked packages.

## 2026-06-11 — Academic writing pipeline

- PDF export switched to tectonic; BasicTeX dropped.
- CMOS 18e became the default CSL (17e kept, set per document);
  `writing/pandoc/defaults.yaml` became the one shared pipeline for both Neovim
  and `mdexport`.
- Added the `site` function, `mdarchive`, and the docx round-trip now called
  `docx2md`.

## 2026-06-10 — Future-proofing audit

- SSH prefers hybrid post-quantum key exchange; ciphers reordered to avoid the
  Terrapin downgrade attack.
- Vale trimmed to `Vale, proselint` globally — 23 alerts down to 1 actionable
  one on a sample paragraph. The rest became per-project opt-ins.
- Added the writing function set (`mdexport`, `words`, `cite`, `linkcheck`,
  `valeinit`, `pdfpages`, `pdfmerge`); Neovim gained async Pandoc export, the
  Zotero citation picker, and `harper_ls`.
- Completion moved `nvim-cmp` → `blink.cmp` (4 plugins collapsed to 1).

## 2026-06-09 — Mail migration

Moved from iCloud to mailbox.org, replacing Apple Mail with NeoMutt and a local
Maildir.

- `mailsync.sh` runs every 5 minutes via a launchd agent; `make neomutt`
  scaffolds the config on first run.

## 2026-06-08 — NeoMutt, repo restructure, Betterfox, macOS defaults

The single biggest day of infrastructure work in the repo's history.

- Full NeoMutt config with GPG, Nord colors, and attachment handlers.
- Six top-level directories replaced the old ad hoc layout; Makefile targets
  collapsed 12 → 9 to match.
- `make macos` for keyboard, Finder, Dock, and screenshot defaults.
- Betterfox tracked as a submodule; `make firefox` merges it with personal
  overrides.
- `make chsh` sets fish as the login shell.

## 2026-06-06 — Nord everywhere; SSH/GPG hardening

- Every themed tool moved from Catppuccin to Nord; the Starship prompt was
  replaced with a native `fish_prompt` (same output, one less dependency).
- Per-host SSH keys with a port-443 fallback; commit signing moved back to GPG
  with an offline master key and per-machine subkeys.

## 2026-06-01 — Audit fixes; MacTeX removed

- Go toolchain removed; `mactex` (17 GB) replaced with `basictex` (~100 MB).
- Vale gained a package set and `vale sync` wired into `make vale`.
- macOS-only functions now fail cleanly elsewhere; generated plists are linted
  before loading.

## 2026-05-31 — Improvements & forward compatibility

- `newdoc` and the first version of `make doctor`.
- Forgejo Actions CI added — later found never to run, and replaced.

## 2026-05-29–30 — Full rewrite: zsh → fish

The repo's biggest single rewrite: every zsh file removed and replaced with
fish, alongside a full Neovim rebuild.

- Fish config from scratch; Neovim rebuilt on `lazy.nvim` with Telescope,
  treesitter, LSP, conform, Vale linting, and the markdown/writing plugins.
- Ghostty and tmux configs added; SSH hardened.
- Weekly Homebrew update agent.
- Removed: all zsh config, zsh4humans, Zim, Powerlevel10k, and the LazyVim
  setup.

---

## Earlier

- **2026-04-06** — Homebrew automation: `homebrewupdate.sh` and its launchd
  agent, installed by `make brewauto`.
- **2026-01-10** — Neovim moved to LazyVim (replaced in the May 2026 rewrite).
- **2025-10-02** — Brewfile consolidated into a single `make apps`.
- **2024-10-29** — Neovim theme updates (Catppuccin variants).
- **2023-10-08** — `exa` → `eza` (`exa` is unmaintained).
- **2023-08-22** — Opus audio conversion script and alias.
- **2023-08-19** — SSH config updated; signing moved to GPG.
- **2022-09-25** — Fixed the weather alias's zip-code handling.
- **2022-03-10** — Removed `mas` from automated updates; it was upgrading App
  Store apps unintentionally.
- **2021-11-24** — `network` alias for `networkQuality`.
- **2021-08** — fzf, zoxide, tmux config, BBEdit functions, `fuck`, and GPG
  config; git aliases moved into `gitconfig`.
- **2021-07-15** — Initial commit: zsh config, SSH config, gitconfig, a
  Makefile for symlinks, and `ipic` (originally by
  [Dr. Drang](https://github.com/drdrang/ipic)).
