function docx2md --description 'Convert a .docx (e.g. returned editor revisions) to markdown'
    # usage: docx2md <file.docx> [all|accept|reject]
    #   all (default) — keep tracked changes visible (insertions/deletions
    #                   as spans, reviewer comments preserved)
    #   accept/reject — apply or discard the tracked changes
    # Embedded images are extracted next to the output (<name>-media/).
    #
    # Named docx2md, not mdimport: /usr/bin/mdimport is macOS's Spotlight
    # indexer, and a fish function of that name shadows it in every session —
    # so following any Spotlight troubleshooting guide would silently run a
    # pandoc docx conversion instead. (Same reason the `rgmd` alias in
    # conf.d/aliases.fish avoids the name `mdfind`.)
    if __help_requested $argv
        echo "usage: docx2md <file.docx> [all|accept|reject]"
        echo "  all (default)   keep tracked changes visible"
        echo "  accept|reject   apply or discard the tracked changes"
        return 0
    end

    __require docx2md pandoc; or return 1

    if test (count $argv) -eq 0
        echo "usage: docx2md <file.docx> [all|accept|reject]" >&2
        return 1
    end

    set -l in $argv[1]
    set -l track all
    if test (count $argv) -ge 2
        set track $argv[2]
    end

    if not contains $track all accept reject
        echo "docx2md: mode must be all, accept, or reject" >&2
        return 1
    end

    if not test -f $in
        echo "docx2md: no such file: $in" >&2
        return 1
    end

    set -l out (path change-extension md $in)
    if test -e $out
        echo "docx2md: refusing to overwrite existing $out" >&2
        return 1
    end

    pandoc --track-changes=$track \
        --extract-media=(path change-extension '' $in)-media \
        $in -o $out
    and echo "Wrote $out"
end
