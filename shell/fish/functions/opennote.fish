function opennote --description "Open a citekey's reading/research note in Obsidian"
    # usage: opennote <citekey>
    # Tries READING_NOTES_DIR first, then RESEARCH_NOTES_DIR (the Zotero
    # connector's two export targets — see Meta/templates/Reading Note.md and
    # Archival Note.md). Requires the Advanced URI community plugin in the vault.
    if __help_requested $argv
        echo "usage: opennote <citekey>"
        return 0
    end

    if test (count $argv) -ne 1
        echo "usage: opennote <citekey>" >&2
        return 1
    end
    set -l key (string replace -r '^@' '' -- $argv[1])

    __need_path opennote dir "reading-notes folder" "$READING_NOTES_DIR"; or return 1
    __need_path opennote dir "research-notes folder" "$RESEARCH_NOTES_DIR"; or return 1

    set -l file "$READING_NOTES_DIR/$key.md"
    if not test -f "$file"
        set file "$RESEARCH_NOTES_DIR/$key.md"
    end
    if not test -f "$file"
        echo "opennote: no reading or research note found for citekey: $key" >&2
        return 1
    end

    # Advanced URI addresses a note by vault name + a path relative to the
    # vault root. The vault root is two levels above either notes folder
    # ($HOME/Notes/02 Notes/<folder>) — derived from paths.env rather than
    # hardcoded, so it stays correct if that tree ever moves.
    set -l vault_dir (path dirname (path dirname $READING_NOTES_DIR))
    set -l vault_name (path basename $vault_dir)
    set -l filepath (string replace "$vault_dir/" '' -- $file)

    open "obsidian://advanced-uri?vault="(string escape --style=url -- $vault_name)"&filepath="(string escape --style=url -- $filepath)
end
