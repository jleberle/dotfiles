function archverify --description 'Generate or verify a SHA-256 manifest of the archival scans (detects corruption / bit-rot)'
    # usage: archverify            verify current files against the stored manifest
    #        archverify --update   (re)generate the manifest after adding/removing scans
    #
    # The Sullivan-style scans are irreplaceable primary sources. This records a
    # checksum of every file under 03 Research/Archives so silent corruption — a
    # bad copy, a partial sync, disk bit-rot — is detectable. Run --update when
    # you add scans; run plain archverify periodically (or before a backup).
    set -l archives ~/Notes/03\ Research/Archives
    if not test -d $archives
        echo "archverify: archive folder not found: $archives" >&2
        return 1
    end

    pushd $archives >/dev/null
    if test "$argv[1]" = --update
        # Only the irreplaceable scans (PDFs/images), not the editable .md docs —
        # otherwise editing the README would trip a false "corruption" alarm.
        find . -type f ! -iname '*.md' ! -name checksums.sha256 ! -name '.DS_Store' -print0 \
            | sort -z | xargs -0 shasum -a 256 >checksums.sha256
        echo "archverify: manifest updated ("(wc -l <checksums.sha256 | string trim)" files)"
        popd >/dev/null
        return 0
    end

    if not test -f checksums.sha256
        echo "archverify: no manifest yet — run 'archverify --update' first" >&2
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
