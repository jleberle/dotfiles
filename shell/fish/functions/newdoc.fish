function newdoc --description 'Create a new Markdown document pre-filled with Pandoc metadata'
    # usage: newdoc <filename> [title]
    if test (count $argv) -eq 0
        echo "usage: newdoc <filename> [title]" >&2
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
