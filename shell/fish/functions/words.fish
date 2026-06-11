function words --description 'Prose word count via pandoc (excludes frontmatter, markdown syntax, URLs)'
    # usage: words <file.md> [more.md ...]
    # `wc -w` over-counts markdown (YAML frontmatter, citekeys, link URLs,
    # crossref labels); converting to plain text first counts what a reader
    # — or a journal's word limit — actually sees.
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
        or begin
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
