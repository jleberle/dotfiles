function archverify --description 'Generate or verify a SHA-256 manifest of the archival scans (detects corruption / bit-rot)'
    # usage: archverify            verify current files against the stored manifest
    #        archverify update     (re)generate the manifest after adding/removing scans
    #
    # `update` is a subcommand WORD, not a flag, because it selects a different
    # action. The repo's rule: words choose what a command does (archbackup
    # snapshots|check, site <cmd>, docx2md all|accept|reject); flags modify how it
    # does it (zotcheck --list, readnote --primary, csvsort --header). This was
    # `--update` before that rule was written down, so the flag still works.
    #
    # The Sullivan-style scans are irreplaceable primary sources. This records a
    # checksum of every file under 03 Research/Archives so silent corruption — a
    # bad copy, a partial sync, disk bit-rot — is detectable. Run `update` when
    # you add scans; run plain archverify periodically (or before a backup).
    if __help_requested $argv
        echo "usage: archverify            verify files against the stored manifest"
        echo "       archverify update     regenerate the manifest"
        return 0
    end

    # Anything else used to fall through to a verify run, so a typo'd subcommand
    # silently did the opposite of what was asked.
    if test (count $argv) -gt 0; and not contains -- "$argv[1]" update --update
        echo "archverify: unknown argument '$argv[1]'" >&2
        echo "        run: archverify   (verify)   or   archverify update   (regenerate)" >&2
        return 1
    end

    set -l archives $RESEARCH_ARCHIVES_DIR
    __need_path archverify dir "archive folder" "$archives"; or return 1

    pushd $archives >/dev/null
    if contains -- "$argv[1]" update --update
        # Only the irreplaceable scans (PDFs/images), not the editable .md docs —
        # otherwise editing the README would trip a false "corruption" alarm.
        find . -type f ! -iname '*.md' ! -name checksums.sha256 ! -name '.DS_Store' -print0 \
            | sort -z | xargs -0 shasum -a 256 >checksums.sha256
        echo "archverify: manifest updated ("(wc -l <checksums.sha256 | string trim)" files)"
        popd >/dev/null
        return 0
    end

    if not test -f checksums.sha256
        echo "archverify: no manifest yet — run 'archverify update' first" >&2
        popd >/dev/null
        return 1
    end

    shasum -a 256 -c checksums.sha256 2>/dev/null | grep -v ': OK$'
    set -l rc $pipestatus[1]
    popd >/dev/null

    if test $rc -eq 0
        echo "archverify: OK — all files match the manifest"
    else
        echo "archverify: MISMATCH — files listed above failed; investigate before trusting them" >&2
    end
    return $rc
end
