function depmerge --description 'Rebase and fast-forward merge a GitHub Dependabot PR into main'
    # usage: depmerge <pr-number>
    if __help_requested $argv
        echo "usage: depmerge <pr-number>"
        return 0
    end

    if test (count $argv) -ne 1
        echo "usage: depmerge <pr-number>" >&2
        return 1
    end

    if not string match -qr '^[0-9]+$' -- $argv[1]
        echo "depmerge: PR number must be numeric" >&2
        return 1
    end

    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "depmerge: not inside a git repository" >&2
        return 1
    end

    set -l untracked (git ls-files --others --exclude-standard)
    if not git diff --quiet; or not git diff --cached --quiet; or test (count $untracked) -gt 0
        echo "depmerge: working tree is not clean; commit/stash first" >&2
        return 1
    end

    __require depmerge gh; or return 1

    set -l github_remote (git remote get-url origin 2>/dev/null)
    if test -z "$github_remote"
        echo "depmerge: no origin remote found" >&2
        return 1
    end

    set -l pr $argv[1]
    set -l github_repo (string replace -r '^github:|^(ssh://)?git@github\.com[:/]|^https?://github\.com/' '' -- $github_remote | string replace -r '\.git$' '')

    set -l pr_author (gh pr view --repo $github_repo $pr --json author --jq '.author.login'); or return 1
    set -l pr_base (gh pr view --repo $github_repo $pr --json baseRefName --jq '.baseRefName'); or return 1
    set -l pr_state (gh pr view --repo $github_repo $pr --json state --jq '.state'); or return 1
    if not contains -- $pr_author app/dependabot dependabot 'dependabot[bot]'
        echo "depmerge: PR #$pr is not authored by Dependabot" >&2
        return 1
    end
    if test "$pr_base" != main; or test "$pr_state" != OPEN
        echo "depmerge: PR #$pr must be open and target main" >&2
        return 1
    end

    git switch main; or return 1
    git pull --ff-only origin main; or return 1

    gh pr checks --watch --fail-fast --repo $github_repo $pr; or return 1

    # Merge entirely server-side. This used to be `gh pr update-branch --rebase`
    # (rewrite the PR branch), then a local `git fetch` + `git merge --ff-only` +
    # `git push` of the result. That update-branch call rebases AS YOU -- GitHub
    # can't sign a commit it's attributing to your account -- and the local merge
    # then carried that unsigned commit straight onto main. Once `main` required
    # signed commits (including for admins), that unsigned commit would have been
    # rejected at push -- but the version of this script that HAD update-branch
    # already put one in history before signing was enforced (see docs/git.md).
    # `gh pr merge --rebase` performs the whole rebase-and-merge as a single
    # GitHub-authored operation, so the commit that lands on main is signed by
    # GitHub the same way Dependabot's own commits are -- there is no unsigned
    # intermediate for a signature-required main to reject.
    gh pr merge --rebase --repo $github_repo $pr; or return 1

    # The merge just happened on GitHub, not in this checkout -- pull it down so
    # local main matches what was pushed rather than sitting one commit behind.
    git pull --ff-only origin main; or return 1

    echo "depmerge: merged PR #$pr into main and pushed to GitHub"
end
