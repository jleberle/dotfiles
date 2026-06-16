function archcheck --description 'List archival PDFs with no OCR text layer (invisible to archgrep)'
    # usage: archcheck
    # Every scan under 03 Research/Archives should be OCR'd (ocrmypdf) so its text
    # is searchable. This flags any PDF whose text layer is empty — run
    # `ocrmypdf --skip-text` on the ones listed, then archgrep will see them.
    set -l archives ~/Notes/03\ Research/Archives
    if not type -q pdftotext
        echo "archcheck: pdftotext not found — brew install poppler" >&2
        return 1
    end
    if not test -d $archives
        echo "archcheck: archive folder not found: $archives" >&2
        return 1
    end

    set -l missing 0
    set -l total 0
    for f in (find $archives -type f -iname '*.pdf' | sort)
        set total (math $total + 1)
        # First few pages are enough: ocrmypdf adds a text layer to every page,
        # so a non-OCR'd scan has no text anywhere.
        set -l text (pdftotext -l 3 "$f" - 2>/dev/null | string trim)
        if test -z "$text"
            echo "NO TEXT:"(string replace $archives '' $f)
            set missing (math $missing + 1)
        end
    end

    if test $missing -eq 0
        echo "archcheck: all $total PDFs have a text layer"
    else
        echo "archcheck: $missing of $total PDFs need OCR (listed above)" >&2
        return 1
    end
end
