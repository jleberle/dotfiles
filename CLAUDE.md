# dotfiles — session notes

Operational knowledge for working on this repo. README.md is the setup guide
and `docs/` covers each subsystem (`automation`, `git`, `mail`, `maintenance`,
`security`, `shell`, `writing`) — this file is only what those don't say.

## The path is hard-coded and that is deliberate

Every symlink in the `Makefile`, plus `git/gitconfig`, `paths.env`, the launchd
plists, and the pandoc template, is rooted at `~/git/dotfiles`. Cloning
anywhere else breaks all of them, so every target that writes to the machine
depends on `require-location` and stops with an explanation instead. Don't
"fix" this by parameterizing the path — the plists and gitconfig can't read a
variable.

## Clone needs `--recurse-submodules`

`security/betterfox` is a submodule (upstream Betterfox). A plain clone leaves
it empty and `make firefox` produces a `user.js` missing the hardening base,
with no error. `git submodule update --init` after the fact.

## This repo is the authority on tool *presence*

`homebrew/brewfile` + `dots brew-check` is the single check for "is the tool
installed." Other repos deliberately defer to it — `~/git/website`'s
`doctor.sh` used to duplicate it and was changed to stop. When adding a
dependency to any project here, add it to the brewfile rather than adding
another presence check downstream.

## `make install` also installs scheduled jobs

It is not only symlinks — it loads the launchd plists (`brewupdate`,
`decksync`, `resticcheck`, `mailsync`). A job that "isn't running" on a new
machine usually means `make install` was skipped or run before the target
config existed.

`make harden` and `make touchid` are deliberately **not** part of `install`:
they need sudo and change system state beyond this repo. Same for `make macos`
and `make chsh`.

## fish functions are the user-facing surface

`shell/fish/functions/` is where the day-to-day commands live — `dots`, `site`
(a thin wrapper over `~/git/website`'s scripts that only removes the `cd`),
`gitstatus`, `pushrepos`, `cite`, `citecheck`, `linkcheck`.

**Prefer extending an existing function to adding a near-duplicate.** The
helpers `__help_requested`, `__require`, `__need_path`, and `__site_registry`
exist so every function handles `--help` and missing-dependency cases the same
way; a new function that skips them is inconsistent in a way lint won't catch.

Logic that needs real testing gets **extracted to `bin/` as Python** and called
from the fish wrapper — that is why `bin/citecheck.py` and `bin/zotcheck.py`
exist alongside `citecheck.fish` / `zotcheck.fish`. Quoting non-trivial logic
through a fish string is how those got hard to edit in the first place.

## Two repo-status tools, deliberately

`gitstatus` (fish function) is the fast, **offline**, git-only check — dirty
trees and ahead/behind across `~/git`. Unchanged; keep it that way.

`dots status` (`bin/projectstatus.py`) is the wider one: it adds CI state via
`gh` (network) and **pipeline staleness** — whether a repo that generates files
into another repo is ahead of what it generated. Only `~/git/cv` and
`~/git/syllabi` do that, and neither shows up as a dirty tree anywhere, because
the generated files are committed in the *website* repo. That is how the course
pages drifted a full academic year behind their syllabi with nothing reporting
it.

The staleness probes compare **content**, and both cheaper checks are wrong —
`make -q` compares mtimes (git does not preserve them) and treats every
`.PHONY` target as permanently stale, while comparing commit times fails on cv
because `make publish` pushes the website repo first and the source repo last,
so the source commit is always newer even right after a clean publish. The
reasoning is recorded at `PIPELINES` in the script; read it before swapping in
something faster.

## Lint is granular, and `make check` is the gate

`make lint` fans out to `lint-shellcheck`, `lint-fish`, `lint-python`,
`lint-luacheck`, `lint-secrets`, `lint-plists`. There are also drift checks
that compare this repo against machine state: `nvim-drift`, `brew-drift`,
`mail-drift`. Drift is expected and informational — it is not a failure the
way lint is.
