function depmerge --description 'Merge a GitHub Dependabot PR locally, then push to Codeberg + GitHub'
    # usage: depmerge <pr-number>
    # For repos that fetch from Codeberg (canonical) but push to both Codeberg
    # and a private GitHub mirror. Pulls the PR head from GitHub, fast-forwards
    # local main, pushes once, then deletes the temporary branch.
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

    if not git diff --quiet; or not git diff --cached --quiet
        echo "depmerge: working tree is not clean; commit/stash first" >&2
        return 1
    end

    set -l github_remote (git remote get-url --push --all origin 2>/dev/null | string match -r '.*github\.com[:/].*')[1]
    if test -z "$github_remote"
        echo "depmerge: no GitHub push URL found on origin" >&2
        return 1
    end

    set -l pr $argv[1]
    set -l branch dependabot-pr-$pr

    git switch main; or return 1
    git pull --ff-only origin main; or return 1

    # Fetch the exact PR head from GitHub into a disposable local branch.
    git fetch $github_remote +refs/pull/$pr/head:refs/heads/$branch; or return 1
    git merge --ff-only $branch; or return 1
    git push; or return 1
    git branch -D $branch >/dev/null

    echo "depmerge: merged PR #$pr into main and pushed to Codeberg + GitHub"
end
