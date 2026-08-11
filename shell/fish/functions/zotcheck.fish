function zotcheck --description 'Reconcile reading/research notes against the Zotero library (orphans + missing notes)'
    # usage: zotcheck            summary: orphaned notes + count of items lacking a note
    #        zotcheck --list     also list every Zotero item that has no note yet
    #
    # Two failure modes this catches:
    #   - a note whose citekey is no longer in Zotero (key drifted or item
    #     deleted) — its [[links]] and @citations are now broken;
    #   - a Zotero item with no note — a source you have not processed.
    if __help_requested $argv
        echo "usage: zotcheck            orphaned notes + count of items lacking a note"
        echo "       zotcheck --list     also list every Zotero item with no note yet"
        return 0
    end

    set -l lib $ZOTERO_LIBRARY_JSON
    __need_path zotcheck file "Zotero library" "$lib" "export Better CSL JSON from Zotero"; or return 1

    $DOTFILES_DIR/bin/zotcheck.py $lib $READING_NOTES_DIR $RESEARCH_NOTES_DIR $argv
end
