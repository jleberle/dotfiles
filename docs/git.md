# Git

What the tracked `gitconfig` gives you, in short: every commit is
cryptographically signed, every commit is scanned for accidentally staged
secrets before it lands, and a set of quality-of-life defaults smooths the
rough edges of day-to-day git.

**Signing:** GPG commit/tag signing is enabled (`gpg.format = openpgp`; the
signing key is the GPG primary key fingerprint). The same key is registered on
GitHub, so commits show as verified there.

GitHub *enforces* this: `main` has branch protection with "require signed
commits" and "do not allow bypassing" (`enforce_admins`) both on, so an unsigned
commit is rejected at push time rather than landing quietly. That makes the
guarantee mechanical instead of a convention — but it also means a machine where
signing is broken (no key imported, `make git` never run, expired key) cannot
push to `main` at all until signing works or the protection is turned off. Check
what GitHub thinks with:

```sh
gh api repos/<you>/dotfiles/commits/main --jq '.commit.verification'
```

**Diffs:** `delta` renders diffs and logs (Nord theme). It must be installed
before `make git` is run, or `git diff`/`git log` will fail — `make apps`
installs it.

**Sensible defaults baked in:**

- `pull.rebase`, `rebase.autoStash` + `updateRefs` — pulls rebase instead of
  creating merge bubbles, stashing/restoring dirty work automatically
- `push.autoSetupRemote` + `push.default = current` — first push of a new
  branch just works, no `--set-upstream` incantation
- `fetch.prune` — deleted remote branches disappear locally too
- `rerere.enabled` — git remembers how you resolved a conflict and reapplies it
- `diff.algorithm = histogram`, `merge.conflictstyle = zdiff3` — better diffs
  and more readable conflict markers
- `help.autocorrect = prompt`, `init.defaultBranch = main`, branches sorted by
  most-recent commit
- a commit-message template (`git/gitmessage` → `~/.gitmessage`) prefills
  subject/body guidance for manual commits

**Secret scanning:** `core.hooksPath = ~/git/dotfiles/git/hooks` points every
repo at a tracked `pre-commit` hook that runs `gitleaks` on staged changes,
blocking accidental secret commits (the guard for `acp`'s
`git add . && git push`). The hook fails *open* if gitleaks isn't installed
(warns, allows) so commits still work everywhere; `make apps` installs it.
Bypass a false positive with `git commit --no-verify`. NOTE: a repo that sets
its own `core.hooksPath` (e.g. husky) overrides this, so the scan won't run
there.

**Website preflight:** the same `core.hooksPath` also supplies a `pre-push`
hook that runs `scripts/preflight.sh` before a push is allowed to leave the
machine. Because `core.hooksPath` is global, the hook guards against firing in
unrelated repos by checking for both `scripts/preflight.sh` and `hugo.yaml`
first — in practice that means jaredeberle.org and nothing else; every other
repo is a no-op. Bypass with `git push --no-verify`.

Both hooks are made executable by `make git` and are covered by
`make lint-shellcheck`.

**Object integrity:** `transfer/fetch/receive.fsckObjects = true` rejects
malformed or malicious git objects on clone/fetch.

## Remotes / CI

GitHub is the sole, public, canonical remote for this repo (Codeberg is
archived). `origin` fetches from and pushes to GitHub only:

```sh
git remote set-url origin github:jleberle/dotfiles.git
git remote set-url --push origin github:jleberle/dotfiles.git
```

GitHub Dependabot watches the SHA-pinned GitHub Actions workflow refs weekly
and the Betterfox submodule monthly via
[.github/dependabot.yml](../.github/dependabot.yml).

**Dependabot merge workflow:** review the PR on GitHub, then merge it with the
`depmerge <pr-number>` fish helper: switches to `main`, fast-forwards it,
waits for the PR's checks, then asks GitHub to rebase-merge it — entirely
server-side — and fast-forwards `main` locally to match. It refuses a dirty
worktree.

The merge is deliberately server-side (`gh pr merge --rebase`), not a local
rebase-then-push. An earlier version called `gh pr update-branch --rebase` to
bring a stale PR up to date first: GitHub performs that rebase *as you*, so it
cannot sign the result, and the commit that produced landed on `main` unsigned
(`dfbcaab`) — harmless before signed commits were required on `main`, but a
rejected push afterward. `gh pr merge --rebase` does the whole rebase-and-merge
as one GitHub-authored operation instead, the same way Dependabot's own commits
are signed (`e043bc1`), so there is no unsigned intermediate for a
signature-required `main` to reject.

NOTE: whether `gh pr merge --rebase` rebases a stale PR automatically as part
of merging, or requires the PR to already be current, has not been exercised
against a real out-of-date PR from this machine — GitHub's merge endpoint is
documented to handle it, but confirm on the next Dependabot PR that needs
rebasing. If it refuses instead of rebasing, updating the PR branch from
GitHub's own "Update branch" button on the PR page before re-running `depmerge`
is the fallback to try — that path has not been checked against signing
either, so verify the result the same way:

```sh
gh api repos/<you>/dotfiles/commits/main --jq '.commit.verification'
```

**Scheduled CI:** GitHub Actions still runs the full check suite monthly (catches
drift from upstream tool/package changes between pushes), but it no longer
files or closes issues on the result — that required `issues: write`, and CI's
permissions are read-only (`contents: read`). Check the Actions tab for the
monthly run's status.

NOTE: GitHub disables a repository's scheduled workflows after 60 days with no
activity, emailing the repo owner. This repo can easily go that long between
commits, and the macOS-native job (plists, Automator bundles, headless Neovim)
runs *only* on the schedule or `workflow_dispatch` — so it would stop with no
failure to notice, just absence. If the monthly runs have gone quiet, look for
the "disabled due to inactivity" banner on the Actions tab, or run
`gh run list --workflow=ci.yml --event=schedule --limit 10`. Re-enable it there;
`workflow_dispatch` runs it on demand meanwhile.

## Git aliases

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

Shell-side git abbreviations (`gs`, `ga`, `gc`, …) are listed in
[Shell → Aliases](shell.md#aliases).
