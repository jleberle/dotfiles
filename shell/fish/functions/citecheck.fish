function citecheck --description 'Check every @citekey in a draft exists in the Zotero CSL JSON export'
    # usage: citecheck <file.md> [more.md ...]
    # Catches broken pandoc citations (typos, deleted items, key drift) before
    # export — otherwise they render as "???" or silently vanish in the PDF.
    # Supports both normal @citekey and suppressed-author -@citekey forms.
    if __help_requested $argv
        echo "usage: citecheck <file.md> [more.md ...]"
        return 0
    end

    if test (count $argv) -eq 0
        echo "usage: citecheck <file.md> [more.md ...]" >&2
        return 1
    end
    set -l lib $ZOTERO_LIBRARY_JSON
    if not test -f $lib
        echo "citecheck: library not found: $lib — export Better CSL JSON from Zotero" >&2
        return 1
    end

    $DOTFILES_DIR/bin/citecheck.py $lib $argv
end
