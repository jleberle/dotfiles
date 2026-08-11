function mdexport --description 'Pandoc-export markdown files (crossref + citeproc, sibling metadata.yaml)'
    # usage: mdexport <format> <file.md> [more.md ...]
    # e.g.:  mdexport docx chapter-*.md
    # Mirrors the nvim <leader>p mappings — both use the shared pipeline in
    # writing/pandoc/defaults.yaml (crossref + citeproc). Runs from each
    # document's own directory so relative paths in metadata.yaml
    # (bibliography, CSL) and relative images resolve.
    if __help_requested $argv
        echo "usage: mdexport <html|pdf|docx|...> <file.md> [more.md ...]"
        return 0
    end

    __require mdexport pandoc; or return 1

    set -l defaults "$DOTFILES_DIR/writing/pandoc/defaults.yaml"
    __need_path mdexport file "pandoc defaults" "$defaults"; or return 1

    if test (count $argv) -lt 2
        echo "usage: mdexport <html|pdf|docx|...> <file.md> [more.md ...]" >&2
        return 1
    end

    set -l ext $argv[1]
    set -l failed 0

    for file in $argv[2..-1]
        if not test -f "$file"
            echo "mdexport: no such file: $file" >&2
            set failed 1
            continue
        end

        set -l name (path basename $file)
        set -l out (path change-extension $ext $name)

        set -l meta_args
        if test -f (path dirname $file)/metadata.yaml
            set meta_args --metadata-file=metadata.yaml
        end

        pushd (path dirname $file)
        # Pandoc exits 0 for an unresolvable citation: it warns on stderr and
        # writes "smith2020?" into the document. Deciding on the exit status
        # alone printed "Exported chapter.docx" directly beneath a warning that
        # the citations are broken. stderr is captured so the warning can be
        # restated after the filename, attached to the file it describes, and
        # so the run exits non-zero.
        set -l err (mktemp)
        if pandoc -d $defaults $name -o $out $meta_args 2>$err
            if test -s $err
                echo "Exported "(path dirname $file)/$out" — WITH WARNINGS:" >&2
                cat $err >&2
                echo "        check it before sending it on; 'citecheck $name' finds bad citekeys" >&2
                set failed 1
            else
                echo "Exported "(path dirname $file)/$out
            end
        else
            cat $err >&2
            echo "mdexport: pandoc failed for $file" >&2
            set failed 1
        end
        rm -f $err
        popd
    end

    return $failed
end
