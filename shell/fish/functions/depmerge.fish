function depmerge --description 'Rebase and merge a GitHub Dependabot PR into Codeberg + GitHub'
    # usage: depmerge <pr-number>
    # For repos that fetch from Codeberg (canonical) but push to both Codeberg
    # and a private GitHub mirror. Rebases the PR through GitHub, waits for its
    # checks, fast-forwards local main, then pushes it to both hosts.
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

    if not command -q gh
        echo "depmerge: gh is not installed" >&2
        return 1
    end

    set -l push_urls (git remote get-url --push --all origin 2>/dev/null)
    set -l codeberg_remote (string match -r '^codeberg:.*|.*codeberg\.org[:/].*' -- $push_urls)[1]
    set -l github_remote (string match -r '^github:.*|.*github\.com[:/].*' -- $push_urls)[1]
    if test -z "$codeberg_remote"
        echo "depmerge: no Codeberg push URL found on origin" >&2
        return 1
    end
    if test -z "$github_remote"
        echo "depmerge: no GitHub push URL found on origin" >&2
        return 1
    end

    set -l pr $argv[1]
    set -l github_repo (string replace -r '^github:|^(ssh://)?git@github\.com[:/]|^https?://github\.com/' '' -- $github_remote | string replace -r '\.git$' '')

    git switch main; or return 1
    git pull --ff-only $codeberg_remote main; or return 1

    gh pr update-branch --rebase --repo $github_repo $pr; or return 1
    gh pr checks --watch --fail-fast --repo $github_repo $pr; or return 1

    git fetch $github_remote refs/pull/$pr/head; or return 1
    git merge --ff-only FETCH_HEAD; or return 1
    git push $codeberg_remote main:main; or return 1
    git push $github_remote main:main; or return 1

    echo "depmerge: merged PR #$pr into main and pushed to Codeberg + GitHub"
end
