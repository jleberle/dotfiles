function __site_registry --description 'Command table for `site` — one source for dispatch, help, and completions'
    # Five tab-separated columns: name(|alias)  group  runner  usage  description
    #
    # ONE table, three consumers: site.fish dispatches from it, prints its help
    # from it, and completions/site.fish completes from it.
    #
    # It exists because those were three hand-maintained lists and they drifted.
    # The help text advertised `sync-reading`, `newbook` and `finishbook` long
    # after those scripts were removed, so the failure mode was a person typing
    # a command the tool itself had just recommended and getting "No such file
    # or directory" — the worst possible message, since it implicates the user
    # rather than the stale list that suggested it.
    #
    # `runner` is a command line relative to the repo root. site.fish checks
    # that any .sh/.py in it actually exists before running, so if this table
    # goes stale again the error names the table instead of blaming the user.
    #
    # The tabs come from the format string: printf cycles it over the argument
    # list, so each group of five below is one row. Escapes are NOT processed
    # inside %s arguments, which is why the separators can't live in the rows.
    printf '%s\t%s\t%s\t%s\t%s\n' \
        new write scripts/newpost.sh \
        "<article|review|quote> [--cover] [title]" "Start a draft (created outside the repo)" \
        \
        publish write scripts/publish-draft.sh \
        "[--cover] [--cite] [--push] <draft>" "Move a finished draft into content/" \
        \
        images write scripts/add-images.sh \
        "<post-dir> [--cover] <img...>" "Convert and attach images to a post" \
        \
        to-avif write scripts/to-avif.sh \
        "[flags] <img...>" "Convert images to AVIF (+ JPEG companion)" \
        \
        cite-refs write scripts/cite-refs.sh \
        "--keys|--bibliography <file>" "Pull citation keys or render a Works Cited list" \
        \
        newsource reading scripts/newsource.sh \
        "[book|article|zotero] [title|citekey]" "Add a work to the bibliography" \
        \
        finishsource reading scripts/finishsource.sh \
        "[--push] <slug>" "Mark a source read, then ship it" \
        \
        open reading scripts/open-source.sh \
        "<citekey>" "Open a source's note in Obsidian" \
        \
        window reading "python3 scripts/reading-window.py" \
        "" "Show which reading events Micro.blog can still re-import" \
        \
        "check|preflight" check scripts/preflight.sh \
        "[--strict] [--full]" "Pre-push gate; --full runs exactly what CI runs" \
        \
        serve check "hugo server -D --navigateToChanged" \
        "[hugo flags]" "Preview at localhost:1313, drafts included" \
        \
        ship publish scripts/ship.sh \
        "[--full] [--yes] [message]" "Check, commit everything, push" \
        \
        logwriting publish scripts/log-writing.sh \
        "" "End of session: count the vault, publish the writing log" \
        \
        archive maintain scripts/archive-links.sh \
        "[--dry-run] [--all|files...]" "Repoint dead links at Wayback snapshots" \
        \
        csp maintain scripts/csp-hashes.sh \
        "[--check|--write]" "Reconcile CSP hashes in static/_headers" \
        \
        security maintain scripts/sign-security-txt.sh \
        "[--check [--days N]]" "Re-sign security.txt, or check its expiry" \
        \
        hugo-version maintain scripts/sync-hugo-version.sh \
        "" "Bump the Hugo version pinned in statichost.yml"
end
