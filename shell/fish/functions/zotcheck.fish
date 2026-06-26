function zotcheck --description 'Reconcile reading/research notes against the Zotero library (orphans + missing notes)'
    # usage: zotcheck            summary: orphaned notes + count of items lacking a note
    #        zotcheck --list     also list every Zotero item that has no note yet
    #
    # Two failure modes this catches:
    #   - a note whose citekey is no longer in Zotero (key drifted or item
    #     deleted) — its [[links]] and @citations are now broken;
    #   - a Zotero item with no note — a source you have not processed.
    set -l lib $ZOTERO_LIBRARY_JSON
    if not test -f $lib
        echo "zotcheck: library not found: $lib" >&2
        return 1
    end

    $DOTFILES_DIR/bin/zotcheck.py $lib $READING_NOTES_DIR $RESEARCH_NOTES_DIR $argv
end
