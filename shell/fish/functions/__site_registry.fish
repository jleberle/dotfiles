function __site_registry --description 'Command table for `site` — one source for dispatch, help, and completions'
    # Six tab-separated columns:
    #   name(|alias)  group  runner  usage  description  takes-paths
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
    # `takes-paths` is `paths` for commands whose arguments are files or
    # directories, `-` for everything else. site.fish rewrites arguments to
    # absolute paths before cd-ing into the repo, and it needs to know which
    # commands that applies to: it used to absolutize any argument that merely
    # matched something in the current directory, so `site newsource book Notes`
    # run beside a folder called Notes silently retitled the source
    # /Users/you/.../Notes. Titles, slugs and citekeys are never paths.
    #
    # The tabs come from the format string: printf cycles it over the argument
    # list, so each group of six below is one row. Escapes are NOT processed
    # inside %s arguments, which is why the separators can't live in the rows.
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        doctor setup scripts/doctor.sh \
        "[--quiet]" "Check this checkout is configured correctly (not tool installation — dots brew-check)" - \
        \
        new write scripts/newpost.sh \
        "<article|review|quote> [--cover] [title]" "Start a draft (created outside the repo)" - \
        \
        publish write scripts/publish-draft.sh \
        "[--cover] [--cite] [--push] <draft>" "Move a finished draft into content/" paths \
        \
        images write scripts/add-images.sh \
        "<post-dir> [--cover] <img...>" "Convert and attach images to a post" paths \
        \
        to-avif write scripts/to-avif.sh \
        "[flags] <img...>" "Convert images to AVIF (+ JPEG companion)" paths \
        \
        cite-refs write scripts/cite-refs.sh \
        "--keys|--bibliography <file>" "Pull citation keys or render a Works Cited list" paths \
        \
        newsource reading scripts/newsource.sh \
        "[book|article|zotero] [title|citekey]" "Add a work to the bibliography" - \
        \
        finishsource reading scripts/finishsource.sh \
        "[--push] <slug>" "Mark a source read, then ship it" - \
        \
        "check|preflight" check scripts/preflight.sh \
        "[--strict] [--full]" "Pre-push gate; --full runs exactly what CI runs" - \
        \
        serve check "hugo server -D --navigateToChanged" \
        "[hugo flags]" "Preview at localhost:1313, drafts included" - \
        \
        ship publish scripts/ship.sh \
        "[--full] [--yes] [message]" "Check, commit everything, push" - \
        \
        logwriting publish scripts/log-writing.sh \
        "" "End of session: count the vault, publish the writing log" - \
        \
        archive maintain scripts/archive-links.sh \
        "[--dry-run] [--all|files...]" "Repoint dead links at Wayback snapshots" paths \
        \
        security maintain scripts/sign-security-txt.sh \
        "[--check [--days N]]" "Re-sign security.txt, or check its expiry" -
end
