function depmerge --description 'Rebase and fast-forward merge a GitHub Dependabot PR into main'
    # usage: depmerge <pr-number>
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

    if not command -q gh
        echo "depmerge: gh is not installed" >&2
        return 1
    end

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

    gh pr update-branch --rebase --repo $github_repo $pr; or return 1
    gh pr checks --watch --fail-fast --repo $github_repo $pr; or return 1

    git fetch origin refs/pull/$pr/head; or return 1
    git merge --ff-only FETCH_HEAD; or return 1
    git push origin main:main; or return 1

    echo "depmerge: merged PR #$pr into main and pushed to GitHub"
end
