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
        echo "  ship [--full] [--yes] [message]               preflight, commit -A, push (ship.sh)" >&2
        echo "  serve                                         hugo server -D --navigateToChanged" >&2
        echo "  archive [--dry-run] [--all|files...]          replace dead links (archive-links.sh)" >&2
        echo "  cite-refs --keys|--bibliography FILE          citation helpers for drafts (cite-refs.sh)" >&2
        echo "  to-avif [flags] <img...>                      convert images to avif/jpg (to-avif.sh)" >&2
        echo "  sync-reading <citekey> [book|article]          scaffold a reading-ledger entry (sync-reading.sh)" >&2
        echo "  newsource [book|article] [title]              new reading-ledger entry (newsource.sh)" >&2
        echo "  newbook [title]                               new book ledger entry (newbook.sh)" >&2
        echo "  finishsource [--push] [slug]                  mark a reading-ledger entry finished (finishsource.sh)" >&2
        echo "  finishbook [--push] [slug]                    mark a book ledger entry finished (finishbook.sh)" >&2
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
        case ship
            ./scripts/ship.sh $args
            set rc $status
        case serve
            hugo server -D --navigateToChanged
            set rc $status
        case archive
            ./scripts/archive-links.sh $args
            set rc $status
        case cite-refs
            ./scripts/cite-refs.sh $args
            set rc $status
        case to-avif
            ./scripts/to-avif.sh $args
            set rc $status
        case sync-reading
            ./scripts/sync-reading.sh $args
            set rc $status
        case newsource
            ./scripts/newsource.sh $args
            set rc $status
        case newbook
            ./scripts/newbook.sh $args
            set rc $status
        case finishsource
            ./scripts/finishsource.sh $args
            set rc $status
        case finishbook
            ./scripts/finishbook.sh $args
            set rc $status
        case '*'
            echo "site: unknown command: $cmd (run 'site' for usage)" >&2
            set rc 1
    end
    popd
    return $rc
end
