function archocr --description 'List archival PDFs with no OCR text layer (invisible to archgrep)'
    # usage: archocr
    # Every scan under 03 Research/Archives should be OCR'd (ocrmypdf) so its text
    # is searchable. This flags any PDF whose text layer is empty — run
    # `ocrmypdf --skip-text` on the ones listed, then archgrep will see them.
    if __help_requested $argv
        echo "usage: archocr   (no arguments)"
        return 0
    end

    set -l archives $RESEARCH_ARCHIVES_DIR
    __require archocr pdftotext; or return 1
    __need_path archocr dir "archive folder" "$archives"; or return 1

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
        echo "archocr: all $total PDFs have a text layer"
    else
        echo "archocr: $missing of $total PDFs need OCR (listed above)" >&2
        return 1
    end
end
