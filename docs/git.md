# Git

What the tracked `gitconfig` gives you, in short: every commit is
cryptographically signed, every commit is scanned for accidentally staged
secrets before it lands, and a set of quality-of-life defaults smooths the
rough edges of day-to-day git.

**Signing:** GPG commit/tag signing is enabled (`gpg.format = openpgp`; the
signing key is the GPG primary key fingerprint). The same key is registered on
both GitHub and Codeberg, so commits show as verified on both.

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

**Secret scanning:** `core.hooksPath = ~/.dotfiles/git/hooks` points every
repo at a tracked `pre-commit` hook that runs `gitleaks` on staged changes,
blocking accidental secret commits (the guard for `acp`'s
`git add . && git push`). The hook fails *open* if gitleaks isn't installed
(warns, allows) so commits still work everywhere; `make apps` installs it.
Bypass a false positive with `git commit --no-verify`. NOTE: a repo that sets
its own `core.hooksPath` (e.g. husky) overrides this, so the scan won't run
there.

**Object integrity:** `transfer/fetch/receive.fsckObjects = true` rejects
malformed or malicious git objects on clone/fetch.

## Remotes / CI mirror

Codeberg stays the public canonical remote for this repo, but CI runs on a
private GitHub mirror. In this clone, `origin` should fetch from Codeberg and
push to both Codeberg and GitHub, so a normal `git push` updates the canonical
repo and triggers GitHub Actions on the mirror. For a fresh clone:

```sh
git remote set-url origin codeberg:jle/dotfiles.git
git remote set-url --push origin codeberg:jle/dotfiles.git
git remote set-url --add --push origin git@github.com:jleberle/dotfiles.git
```

GitHub Dependabot on the private mirror watches the SHA-pinned GitHub Actions
workflow refs weekly and the Betterfox submodule monthly via
[.github/dependabot.yml](../.github/dependabot.yml).
That keeps update PRs reviewable in GitHub without changing Codeberg's role as
the canonical public remote.

**Dependabot merge workflow:** review the PR on GitHub, but merge it locally so
Codeberg and GitHub do not diverge. The `depmerge <pr-number>` fish helper:
switches to `main`, fast-forwards it from Codeberg, asks GitHub to rebase the PR,
waits for its checks, fetches the resulting PR head, fast-forwards locally, and
pushes `main` explicitly to both hosts. It refuses a dirty worktree.

**Scheduled CI:** GitHub Actions still runs the full check suite monthly (catches
drift from upstream tool/package changes between pushes), but it no longer
files or closes issues on the result — that required `issues: write`, and CI's
permissions are read-only (`contents: read`). Check the Actions tab for the
monthly run's status.

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
