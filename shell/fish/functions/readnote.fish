function readnote --description 'Scaffold a reading note from a Zotero citekey (closes the zotcheck loop)'
    # usage: readnote <citekey> [--primary]
    # Creates <citekey>.md in $READING_NOTES_DIR with frontmatter pulled from the
    # Zotero CSL JSON export, in the exact shape zotcheck reconciles — so a
    # "Zotero item with no note yet" becomes a real note in one step. Defaults the
    # source tag to secondary; pass --primary for a primary source. The body
    # opens with a history-oriented scaffold plus any archival metadata Zotero
    # already knows.
    if __help_requested $argv
        echo "usage: readnote <citekey> [--primary]"
        return 0
    end

    argparse primary -- $argv
    or return 1

    if test (count $argv) -ne 1
        echo "usage: readnote <citekey> [--primary]" >&2
        return 1
    end

    # Accept @key or bare key.
    set -l key (string replace -r '^@' '' -- $argv[1])
    set -l source (set -q _flag_primary; and echo primary; or echo secondary)

    if not test -f $ZOTERO_LIBRARY_JSON
        echo "readnote: library not found: $ZOTERO_LIBRARY_JSON — export Better CSL JSON from Zotero" >&2
        return 1
    end
    if not test -d $READING_NOTES_DIR
        echo "readnote: reading-notes dir not found: $READING_NOTES_DIR" >&2
        return 1
    end

    set -l file $READING_NOTES_DIR/$key.md
    if test -e $file
        echo "readnote: note already exists: $file" >&2
        return 1
    end

    # Look up the key and write the note. Exits nonzero (no file created) if the
    # citekey isn't in the library, so we never scaffold an instant orphan.
    $DOTFILES_DIR/bin/readnote.py $key $source $ZOTERO_LIBRARY_JSON $file
    or return 1

    echo "readnote: created "(string replace $HOME '~' $file)
    if status --is-interactive
        nvim $file
    end
end
