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

    if test (count $argv) -lt 2
        echo "usage: mdexport <html|pdf|docx|...> <file.md> [more.md ...]" >&2
        return 1
    end

    set -l ext $argv[1]
    set -l failed 0

    for file in $argv[2..-1]
        if not test -f $file
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
        if pandoc -d $DOTFILES_DIR/writing/pandoc/defaults.yaml $name -o $out $meta_args
            echo "Exported "(path dirname $file)/$out
        else
            echo "mdexport: pandoc failed for $file" >&2
            set failed 1
        end
        popd
    end

    return $failed
end
