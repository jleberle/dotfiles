function newmeta --description 'Write a metadata.yaml into this folder, with the paths already filled in'
    # usage: newmeta   (run in the folder holding the document)
    #
    # mdexport and the nvim <leader>p mappings both pick up a sibling
    # metadata.yaml automatically, so this is how you set bibliography, CSL and
    # reference-doc for a multi-file project (a chapter folder, a co-authored
    # draft) instead of repeating them in every document's frontmatter.
    #
    # This exists because the old advice — `cp .../writing/pandoc/metadata.yaml .`
    # — produced a file that could not work. Pandoc does not expand `~` in
    # document metadata, so both the `bibliography:` and `csl:` lines failed with
    # "not found in resource path" and exit 99, and the template's hardcoded
    # `date:` silently dated every document to the day the template was written.
    # Rendering the paths here is the same thing newdoc already does for
    # frontmatter.
    if __help_requested $argv
        echo "usage: newmeta   (run in the folder holding the document)"
        return 0
    end

    __need_path newmeta file "Zotero library" "$ZOTERO_LIBRARY_JSON" "export Better CSL JSON from Zotero"; or return 1
    set -l tmpl "$DOTFILES_DIR/writing/pandoc/metadata.yaml.tmpl"
    __need_path newmeta file "metadata template" "$tmpl"; or return 1

    if test -e metadata.yaml
        echo "newmeta: metadata.yaml already exists here" >&2
        echo "        edit it, or move it aside first" >&2
        return 1
    end

    set -l author (git config user.name)
    test -n "$author"; or set author "Your Name"

    sed -e "s|__ZOTERO_LIBRARY_JSON__|$ZOTERO_LIBRARY_JSON|g" \
        -e "s|__DOTFILES__|$DOTFILES_DIR|g" \
        -e "s|__AUTHOR__|$author|g" \
        -e "s|__TODAY__|"(date +%Y-%m-%d)"|g" \
        "$tmpl" >metadata.yaml
    or return 1

    echo "Wrote metadata.yaml — set the title, then export with 'mdexport pdf <file.md>'"
end
