function newdoc --description 'Create a new Markdown document pre-filled with Pandoc metadata'
    # usage: newdoc <filename> [title]
    if __help_requested $argv
        echo "usage: newdoc <filename> [title]"
        return 0
    end

    if test (count $argv) -eq 0
        echo "usage: newdoc <filename> [title]" >&2
        return 1
    end

    # The frontmatter written below interpolates both of these. Unset (nvim
    # launched outside fish, or a broken paths.env) used to yield an empty
    # `bibliography:` and a csl: path rooted at /, with exit 0 and the file
    # opened as if nothing were wrong — the breakage only surfaced at export
    # time, months later, as citations rendering "???".
    if not set -q ZOTERO_LIBRARY_JSON; or test -z "$ZOTERO_LIBRARY_JSON"
        echo "newdoc: ZOTERO_LIBRARY_JSON is not set — check paths.env" >&2
        return 1
    end
    if not set -q DOTFILES_DIR; or test -z "$DOTFILES_DIR"
        echo "newdoc: DOTFILES_DIR is not set — check paths.env" >&2
        return 1
    end

    set -l filename $argv[1]
    # Default to Untitled; join any remaining args into the title. (Don't fold
    # this into one `string join … or echo` — string join returns non-zero when
    # there's a single element to join, which would wrongly append "Untitled".)
    set -l title Untitled
    if test (count $argv) -ge 2
        set title (string join " " $argv[2..-1])
    end

    # Append .md if no extension given
    if not string match -q '*.*' $filename
        set filename "$filename.md"
    end

    if test -e $filename
        echo "File already exists: $filename" >&2
        return 1
    end

    set -l today (date +%Y-%m-%d)
    set -l author (git config user.name)

    # CSL defaults to CMOS 18th edition (current since Sept 2024); swap the
    # frontmatter to ...-17th-edition.csl for journals still on 17e. Keep this
    # default in sync with writing/pandoc/metadata.yaml — the CSL must live in
    # document metadata, not defaults.yaml (defaults override frontmatter).
    printf '---\ntitle: "%s"\nauthor: "%s"\ndate: %s\n\nbibliography:\n  - %s\n\ncsl: %s/writing/pandoc/chicago-notes-bibliography-18th-edition.csl\n\nlink-citations: true\n\nreference-doc: %s/writing/pandoc/reference.docx\n\ngeometry: margin=1in\n\nfontsize: 12pt\n\nlinestretch: 1.5\n---\n\n' $title $author $today $ZOTERO_LIBRARY_JSON $DOTFILES_DIR $DOTFILES_DIR > $filename

    nvim $filename
end
