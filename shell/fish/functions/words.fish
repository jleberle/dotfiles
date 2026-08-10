function words --description 'Prose word count via pandoc (excludes frontmatter, markdown syntax, URLs)'
    # usage: words <file.md> [more.md ...]
    # `wc -w` over-counts markdown (YAML frontmatter, citekeys, link URLs,
    # crossref labels); converting to plain text first counts what a reader
    # — or a journal's word limit — actually sees.
    if __help_requested $argv
        echo "usage: words <file.md> [more.md ...]"
        return 0
    end

    if test (count $argv) -eq 0
        echo "usage: words <file.md> [more.md ...]" >&2
        return 1
    end

    set -l total 0
    set -l counted 0

    for file in $argv
        if not test -f $file
            echo "words: no such file: $file" >&2
            continue
        end
        set -l n (pandoc $file -t plain 2>/dev/null | wc -w | string trim)
        # Check pandoc itself via $pipestatus[1], not the pipeline's final status:
        # `wc | string trim` returns 0 even when pandoc fails, so `or` would miss it.
        if test $pipestatus[1] -ne 0
            echo "words: pandoc failed for $file" >&2
            continue
        end
        printf '%8d  %s\n' $n $file
        set total (math $total + $n)
        set counted (math $counted + 1)
    end

    if test $counted -gt 1
        printf '%8d  total\n' $total
    end
end
