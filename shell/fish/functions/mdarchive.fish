function mdarchive --description 'Archive every URL cited in markdown files to the Wayback Machine'
    # usage: mdarchive <file.md> [more.md ...]
    # Combats link rot in citations: extracts URLs with lychee, snapshots each
    # with waybackup (bin/waybackup), prints the archive URL to cite alongside
    # the original. Archiving is slow (the Wayback Machine can take ~30s+ per
    # URL) — expect a wait on link-heavy manuscripts.
    if test (count $argv) -eq 0
        echo "usage: mdarchive <file.md> [more.md ...]" >&2
        return 1
    end

    if not type -q lychee
        echo "mdarchive: lychee not found (run: make apps)" >&2
        return 1
    end

    for file in $argv
        if not test -f $file
            echo "mdarchive: no such file: $file" >&2
            return 1
        end
    end

    set -l urls (lychee --dump $argv 2>/dev/null | string match -r '^https?://.*' | sort -u)

    if test (count $urls) -eq 0
        echo "mdarchive: no http(s) URLs found" >&2
        return 1
    end

    echo "Archiving "(count $urls)" unique URL(s)..."
    set -l failed 0

    for url in $urls
        echo "→ $url"
        set -l snapshot (waybackup $url)
        if test $status -eq 0
            echo "  $snapshot"
        else
            echo "  FAILED" >&2
            set failed 1
        end
    end

    return $failed
end
