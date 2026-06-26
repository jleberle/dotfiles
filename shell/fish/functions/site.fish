function site --description 'Run website (jaredeberle.org) tasks from anywhere'
    # Pure dispatch — all logic lives in $WEBSITE_REPO/scripts/, which stays
    # canonical. This just removes the `cd`.
    set -l repo $WEBSITE_REPO

    if not test -d $repo/scripts
        echo "site: website repo not found at $repo" >&2
        return 1
    end

    if test (count $argv) -eq 0
        echo "usage: site <command> [args]" >&2
        echo "  new <article|review|quote> [--cover] [title]  create ignored draft (newpost.sh)" >&2
        echo "  images <post-dir> [--cover] <img...>          convert + attach images (add-images.sh)" >&2
        echo "  publish <draft>                              publish draft into content (publish-draft.sh)" >&2
        echo "  preflight [--strict] [--full]                 build + CSP + reference gate; --full adds html-validate/a11y/lychee (preflight.sh)" >&2
        echo "  push [--strict] [--full]                      preflight, then git push" >&2
        echo "  serve                                         hugo server -D --navigateToChanged" >&2
        echo "  archive [--dry-run] [--all|files...]          replace dead links (archive-links.sh)" >&2
        echo "  sync-hugo [--dry-run]                         sync CI Hugo version (sync-hugo-version.sh)" >&2
        echo "  csp                                           check CSP hashes (csp-hashes.sh --check)" >&2
        return 1
    end

    set -l cmd $argv[1]

    # The scripts resolve the repo root via `git rev-parse`, so they must run
    # from inside the repo — but arguments like image files are relative to
    # the caller's cwd. Absolutize any argument that exists here; leave
    # repo-relative paths (which don't exist here) and flags untouched.
    set -l args
    for a in $argv[2..-1]
        if test -e $a
            set -a args (path resolve $a)
        else
            set -a args $a
        end
    end

    pushd $repo
    set -l rc 0
    switch $cmd
        case new
            ./scripts/newpost.sh $args
            set rc $status
        case images
            ./scripts/add-images.sh $args
            set rc $status
        case publish
            ./scripts/publish-draft.sh $args
            set rc $status
        case preflight
            ./scripts/preflight.sh $args
            set rc $status
        case push
            # The ritual preflight.sh's own header prescribes.
            ./scripts/preflight.sh $args; and git push
            set rc $status
        case serve
            hugo server -D --navigateToChanged
            set rc $status
        case archive
            ./scripts/archive-links.sh $args
            set rc $status
        case sync-hugo
            ./scripts/sync-hugo-version.sh $args
            set rc $status
        case csp
            ./scripts/csp-hashes.sh --check $args
            set rc $status
        case '*'
            echo "site: unknown command: $cmd (run 'site' for usage)" >&2
            set rc 1
    end
    popd
    return $rc
end
