function newdoc --description 'Create a new Markdown document pre-filled with Pandoc metadata'
    # usage: newdoc <filename> [title]
    if test (count $argv) -eq 0
        echo "usage: newdoc <filename> [title]" >&2
        return 1
    end

    set -l filename $argv[1]
    set -l title (test (count $argv) -ge 2; and string join " " $argv[2..-1]; or echo "Untitled")

    # Append .md if no extension given
    if not string match -q '*.*' $filename
        set filename "$filename.md"
    end

    if test -e $filename
        echo "File already exists: $filename" >&2
        return 1
    end

    set -l today (date +%Y-%m-%d)

    printf '---\ntitle: "%s"\nauthor: "Jared Eberle"\ndate: %s\n\nbibliography:\n  - ~/Documents/Library/Library.bib\n\ncsl: %s/.dotfiles/templates/chicago-notes-bibliography-17th-edition.csl\n\nlink-citations: true\n\nreference-doc: %s/.dotfiles/templates/reference.docx\n\ngeometry: margin=1in\n\nfontsize: 12pt\n\nlinestretch: 1.5\n---\n\n' $title $today $HOME $HOME > $filename

    nvim $filename
end
