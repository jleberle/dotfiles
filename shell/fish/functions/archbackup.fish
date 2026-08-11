function archbackup --description 'Snapshot the archival scans to a restic repo (versioned, encrypted backup)'
    # usage: archbackup            create a new snapshot
    #        archbackup snapshots  list existing snapshots
    #        archbackup check      verify repository integrity
    #
    # One-time setup, per machine that has the drive (universal vars don't sync):
    #   mkdir -p ~/.config/restic
    #   # Write a strong password into the file below — AND save the same password
    #   # in your password manager. It is the ONLY key to the encrypted repo;
    #   # lose it and the backup is permanently unrecoverable, drive intact or not.
    #   chmod 600 ~/.config/restic/archive.pass
    #   set -Ux ARCHIVE_RESTIC_REPO /Volumes/<external-hd>/research-backup
    #   set -Ux RESTIC_PASSWORD_FILE ~/.config/restic/archive.pass   # or RESTIC_PASSWORD
    #   restic -r $ARCHIVE_RESTIC_REPO init
    # The -U (universal) flag matters: without it the vars live only in the shell
    # you set them in, so `init` works but a later `archbackup` errors.
    #
    # restic is versioned + deduplicated + encrypted, so re-running is cheap and
    # old snapshots survive an accidental deletion or a bad sync — unlike a plain
    # rsync mirror, which would faithfully propagate the damage. The external HD
    # stays the offline master (see the Archives README).
    if __help_requested $argv
        echo "usage: archbackup            create a new snapshot"
        echo "       archbackup snapshots  list existing snapshots"
        echo "       archbackup check      verify repository integrity"
        return 0
    end

    set -l archives $RESEARCH_ARCHIVES_DIR
    __require archbackup restic; or return 1
    if not set -q ARCHIVE_RESTIC_REPO
        echo "archbackup: set ARCHIVE_RESTIC_REPO first (see function header)" >&2
        return 1
    end

    # Without a password restic prompts on a tty — and under the weekly launchd
    # job there is no tty, so it just fails. Checked here so the message names
    # the actual problem; `check` below would otherwise misreport it as an
    # unmounted drive and return success.
    if not set -q RESTIC_PASSWORD_FILE; and not set -q RESTIC_PASSWORD
        echo "archbackup: neither RESTIC_PASSWORD_FILE nor RESTIC_PASSWORD is set" >&2
        echo "            (see the one-time setup in the function header)" >&2
        return 1
    end
    if set -q RESTIC_PASSWORD_FILE; and not test -f "$RESTIC_PASSWORD_FILE"
        echo "archbackup: RESTIC_PASSWORD_FILE points at a missing file: $RESTIC_PASSWORD_FILE" >&2
        return 1
    end
    if not test -d $archives
        echo "archbackup: archive folder not found: $archives" >&2
        return 1
    end

    switch "$argv[1]"
        case snapshots
            restic -r $ARCHIVE_RESTIC_REPO snapshots
        case check
            # Verify repository integrity (structure + a sampled subset of the
            # actual data). Turns "I have backups" into "I have restorable
            # backups". Scheduled weekly via org.jaredeberle.resticcheck — see
            # `make resticcheck`.
            #
            # An unmounted drive is the one case that must exit 0: the drive is
            # normally unplugged, and a weekly failure for that would train you
            # to ignore this job's output. EVERYTHING else must exit non-zero.
            # This used to be a single `restic cat config` test whose failure
            # was always blamed on the drive — so a wrong password, a corrupt
            # repo, or a repo that had been deleted all reported "drive
            # unmounted?" and returned success, forever, while verifying
            # nothing. The mount is now tested separately from the repo.
            #
            # Only local repo paths can be tested this way; a remote repo
            # (sftp:/s3:/rest: …) has no local directory, so for those any
            # failure is a real failure.
            if not string match -qr '^[a-z0-9]+:' -- $ARCHIVE_RESTIC_REPO
                if not test -d $ARCHIVE_RESTIC_REPO
                    echo "archbackup: $ARCHIVE_RESTIC_REPO not present (drive unmounted?) — skipping check" >&2
                    return 0
                end
            end

            if not restic -r $ARCHIVE_RESTIC_REPO cat config >/dev/null 2>&1
                echo "archbackup: repo is present but restic cannot read it" >&2
                echo "            check RESTIC_PASSWORD_FILE, or run: restic -r $ARCHIVE_RESTIC_REPO cat config" >&2
                return 1
            end
            restic -r $ARCHIVE_RESTIC_REPO check --read-data-subset=5%
        case '' backup
            restic -r $ARCHIVE_RESTIC_REPO backup $archives --tag archives
        case '*'
            echo "usage: archbackup [snapshots|check]" >&2
            return 1
    end
end
