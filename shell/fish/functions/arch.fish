function arch --description 'Archival scan tools: grep | ocr | verify | backup'
    # usage: arch grep <query> [rg options]   full-text search the OCR'd scans
    #        arch ocr                         list scans missing an OCR text layer
    #        arch verify [update]             SHA-256 manifest verify / regenerate
    #        arch backup [snapshots|check]     restic snapshot / list / integrity check
    #
    # One dispatcher for the four archival-scan commands (grep/ocr/verify/backup
    # used to be separate functions of the same name). All four operate on
    # $RESEARCH_ARCHIVES_DIR — the irreplaceable scans live outside this repo,
    # these are just the tools that touch them.
    if __help_requested $argv
        echo "usage: arch grep <query> [rg options]"
        echo "       arch ocr"
        echo "       arch verify [update]"
        echo "       arch backup [snapshots|check]"
        return 0
    end

    if test (count $argv) -eq 0
        echo "usage: arch <grep|ocr|verify|backup> ..." >&2
        return 1
    end

    set -l sub $argv[1]
    set -l rest $argv[2..-1]
    set -l archives $RESEARCH_ARCHIVES_DIR

    switch $sub
        case grep
            # Searches inside the PDFs in $RESEARCH_ARCHIVES_DIR using ripgrep-all,
            # which reads each PDF's embedded text layer via poppler — no Obsidian
            # plugin or search index to maintain. PDFs must be OCR'd first
            # (`arch ocr` lists the ones that aren't). Extra args pass through to
            # ripgrep, e.g. -l for filenames only, -C3 for more context.
            if test (count $rest) -eq 0
                echo "usage: arch grep <query> [rg options]" >&2
                return 1
            end

            __require "arch grep" rga; or return 1
            __need_path "arch grep" dir "archive folder" "$archives"; or return 1

            # --smart-case: case-insensitive unless the query has an uppercase letter.
            rga --smart-case $rest $archives

        case ocr
            # Every scan under the archive folder should be OCR'd (ocrmypdf) so its
            # text is searchable. This flags any PDF whose text layer is empty — run
            # `ocrmypdf --skip-text` on the ones listed, then `arch grep` will see them.
            __require "arch ocr" pdftotext; or return 1
            __need_path "arch ocr" dir "archive folder" "$archives"; or return 1

            set -l missing 0
            set -l total 0
            for f in (find $archives -type f -iname '*.pdf' | sort)
                set total (math $total + 1)
                # First few pages are enough: ocrmypdf adds a text layer to every
                # page, so a non-OCR'd scan has no text anywhere.
                set -l text (pdftotext -l 3 "$f" - 2>/dev/null | string trim)
                if test -z "$text"
                    echo "NO TEXT:"(string replace $archives '' $f)
                    set missing (math $missing + 1)
                end
            end

            if test $missing -eq 0
                echo "arch ocr: all $total PDFs have a text layer"
            else
                echo "arch ocr: $missing of $total PDFs need OCR (listed above)" >&2
                return 1
            end

        case verify
            # `update` is a subcommand WORD, not a flag, because it selects a
            # different action. The repo's rule: words choose what a command does
            # (`arch backup` snapshots|check, `site <cmd>`, docx2md all|accept|reject);
            # flags modify how it does it (zotcheck --list, readnote --primary,
            # csvsort --header). This was `archverify --update` before that rule was
            # written down; `--update` still works here for the same reason.
            #
            # The scans are irreplaceable primary sources. This records a checksum
            # of every file under the archive folder so silent corruption — a bad
            # copy, a partial sync, disk bit-rot — is detectable. Run `update` when
            # you add scans; run plain `arch verify` periodically (or before a backup).
            if test (count $rest) -gt 0; and not contains -- "$rest[1]" update --update
                echo "arch verify: unknown argument '$rest[1]'" >&2
                echo "        run: arch verify          (verify)" >&2
                echo "        run: arch verify update   (regenerate)" >&2
                return 1
            end

            __need_path "arch verify" dir "archive folder" "$archives"; or return 1

            pushd $archives >/dev/null
            if contains -- "$rest[1]" update --update
                # Only the irreplaceable scans (PDFs/images), not the editable .md
                # docs — otherwise editing the README would trip a false
                # "corruption" alarm.
                find . -type f ! -iname '*.md' ! -name checksums.sha256 ! -name '.DS_Store' -print0 \
                    | sort -z | xargs -0 shasum -a 256 >checksums.sha256
                echo "arch verify: manifest updated ("(wc -l <checksums.sha256 | string trim)" files)"
                popd >/dev/null
                return 0
            end

            if not test -f checksums.sha256
                echo "arch verify: no manifest yet — run 'arch verify update' first" >&2
                popd >/dev/null
                return 1
            end

            shasum -a 256 -c checksums.sha256 2>/dev/null | grep -v ': OK$'
            set -l rc $pipestatus[1]
            popd >/dev/null

            if test $rc -eq 0
                echo "arch verify: OK — all files match the manifest"
            else
                echo "arch verify: MISMATCH — files listed above failed; investigate before trusting them" >&2
            end
            return $rc

        case backup
            # One-time setup, per machine that has the drive (universal vars don't sync):
            #   mkdir -p ~/.config/restic
            #   # Write a strong password into the file below — AND save the same password
            #   # in your password manager. It is the ONLY key to the encrypted repo;
            #   # lose it and the backup is permanently unrecoverable, drive intact or not.
            #   chmod 600 ~/.config/restic/archive.pass
            #   set -Ux ARCHIVE_RESTIC_REPO /Volumes/<external-hd>/research-backup
            #   set -Ux RESTIC_PASSWORD_FILE ~/.config/restic/archive.pass   # or RESTIC_PASSWORD
            #   restic -r $ARCHIVE_RESTIC_REPO init
            # The -U (universal) flag matters: without it the vars live only in the
            # shell you set them in, so `init` works but a later `arch backup` errors.
            #
            # restic is versioned + deduplicated + encrypted, so re-running is cheap
            # and old snapshots survive an accidental deletion or a bad sync — unlike
            # a plain rsync mirror, which would faithfully propagate the damage. The
            # external HD stays the offline master (see the Archives README).
            __require "arch backup" restic; or return 1
            if not set -q ARCHIVE_RESTIC_REPO
                echo "arch backup: set ARCHIVE_RESTIC_REPO first (see function header)" >&2
                return 1
            end

            # Without a password restic prompts on a tty — and under the weekly
            # launchd job there is no tty, so it just fails. Checked here so the
            # message names the actual problem; `check` below would otherwise
            # misreport it as an unmounted drive and return success.
            if not set -q RESTIC_PASSWORD_FILE; and not set -q RESTIC_PASSWORD
                echo "arch backup: neither RESTIC_PASSWORD_FILE nor RESTIC_PASSWORD is set" >&2
                echo "        (see the one-time setup in the function header)" >&2
                return 1
            end
            if set -q RESTIC_PASSWORD_FILE; and not test -f "$RESTIC_PASSWORD_FILE"
                echo "arch backup: RESTIC_PASSWORD_FILE points at a missing file: $RESTIC_PASSWORD_FILE" >&2
                return 1
            end
            __need_path "arch backup" dir "archive folder" "$archives"; or return 1

            switch "$rest[1]"
                case snapshots
                    restic -r $ARCHIVE_RESTIC_REPO snapshots
                case check
                    # Verify repository integrity (structure + a sampled subset of
                    # the actual data). Turns "I have backups" into "I have
                    # restorable backups". Scheduled weekly via
                    # org.jaredeberle.resticcheck — see `make resticcheck`.
                    #
                    # An unmounted drive is the one case that must exit 0: the
                    # drive is normally unplugged, and a weekly failure for that
                    # would train you to ignore this job's output. EVERYTHING else
                    # must exit non-zero. This used to be a single `restic cat
                    # config` test whose failure was always blamed on the drive —
                    # so a wrong password, a corrupt repo, or a repo that had been
                    # deleted all reported "drive unmounted?" and returned success,
                    # forever, while verifying nothing. The mount is now tested
                    # separately from the repo.
                    #
                    # Only local repo paths can be tested this way; a remote repo
                    # (sftp:/s3:/rest: …) has no local directory, so for those any
                    # failure is a real failure.
                    if not string match -qr '^[a-z0-9]+:' -- $ARCHIVE_RESTIC_REPO
                        if not test -d "$ARCHIVE_RESTIC_REPO"
                            echo "arch backup: $ARCHIVE_RESTIC_REPO not present (drive unmounted?) — skipping check" >&2
                            return 0
                        end
                    end

                    if not restic -r $ARCHIVE_RESTIC_REPO cat config >/dev/null 2>&1
                        echo "arch backup: repo is present but restic cannot read it" >&2
                        echo "        check RESTIC_PASSWORD_FILE, or run: restic -r $ARCHIVE_RESTIC_REPO cat config" >&2
                        return 1
                    end
                    restic -r $ARCHIVE_RESTIC_REPO check --read-data-subset=5%
                    set -l check_status $status
                    if test $check_status -ne 0
                        return $check_status
                    end

                    # Record WHEN the backup was last actually verified. The skip
                    # above returns 0 on purpose, which is exactly why this stamp
                    # has to exist: on a machine whose drive is rarely plugged in,
                    # the weekly job logs "skipping check" forever, `make doctor`
                    # reports the agent healthy, and nothing anywhere distinguishes
                    # "verified last Sunday" from "never verified since the repo
                    # was created". `make doctor` reads this file's mtime and says
                    # how old the last PASS is.
                    #
                    # Keyed to restic's exit status, never to a phrase in its
                    # output — a reworded success message in some future restic
                    # would otherwise turn this silently into a permanent "never
                    # verified", which is the same class of bug as the one the
                    # comment above describes.
                    #
                    # Status captured explicitly rather than read after `if not`,
                    # which rewrites it to 0 (same reason bin/homebrewupdate.sh does).
                    mkdir -p $HOME/.local
                    touch $HOME/.local/.restic_verified
                case '' backup
                    restic -r $ARCHIVE_RESTIC_REPO backup $archives --tag archives
                case '*'
                    echo "usage: arch backup [snapshots|check]" >&2
                    return 1
            end

        case '*'
            echo "arch: unknown subcommand '$sub' (grep|ocr|verify|backup)" >&2
            return 1
    end
end
