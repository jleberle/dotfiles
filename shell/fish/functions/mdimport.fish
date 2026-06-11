function mdimport --description 'Convert a .docx (e.g. returned editor revisions) to markdown'
    # usage: mdimport <file.docx> [all|accept|reject]
    #   all (default) — keep tracked changes visible (insertions/deletions
    #                   as spans, reviewer comments preserved)
    #   accept/reject — apply or discard the tracked changes
    # Embedded images are extracted next to the output (<name>-media/).
    if test (count $argv) -eq 0
        echo "usage: mdimport <file.docx> [all|accept|reject]" >&2
        return 1
    end

    set -l in $argv[1]
    set -l track all
    if test (count $argv) -ge 2
        set track $argv[2]
    end

    if not contains $track all accept reject
        echo "mdimport: mode must be all, accept, or reject" >&2
        return 1
    end

    if not test -f $in
        echo "mdimport: no such file: $in" >&2
        return 1
    end

    set -l out (path change-extension md $in)
    if test -e $out
        echo "mdimport: refusing to overwrite existing $out" >&2
        return 1
    end

    pandoc --track-changes=$track \
        --extract-media=(path change-extension '' $in)-media \
        $in -o $out
    and echo "Wrote $out"
end
