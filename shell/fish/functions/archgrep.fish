function archgrep --description "Full-text search the OCR'd archival PDFs (ripgrep-all over the Archives tree)"
    # usage: archgrep <query> [rg options]
    # Searches inside the PDFs in ~/Notes/03 Research/Archives using ripgrep-all,
    # which reads each PDF's embedded text layer via poppler — no Obsidian plugin
    # or search index to maintain. PDFs must be OCR'd first (ocrmypdf; see the
    # Archives README). Extra args pass through to ripgrep, e.g. -l for filenames
    # only, -C3 for more context.
    if test (count $argv) -eq 0
        echo "usage: archgrep <query> [rg options]" >&2
        return 1
    end

    if not type -q rga
        echo "archgrep: rga not found — brew install ripgrep-all" >&2
        return 1
    end

    set -l archives $RESEARCH_ARCHIVES_DIR
    if not test -d $archives
        echo "archgrep: archive folder not found: $archives" >&2
        return 1
    end

    # --smart-case: case-insensitive unless the query has an uppercase letter.
    rga --smart-case $argv $archives
end
