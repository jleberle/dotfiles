function archbackup --description 'Snapshot the archival scans to a restic repo (versioned, encrypted backup)'
    # usage: archbackup            create a new snapshot
    #        archbackup snapshots  list existing snapshots
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
    set -l archives ~/Notes/03\ Research/Archives
    if not type -q restic
        echo "archbackup: restic not found — brew install restic" >&2
        return 1
    end
    if not set -q ARCHIVE_RESTIC_REPO
        echo "archbackup: set ARCHIVE_RESTIC_REPO first (see function header)" >&2
        return 1
    end
    if not test -d $archives
        echo "archbackup: archive folder not found: $archives" >&2
        return 1
    end

    switch "$argv[1]"
        case snapshots
            restic -r $ARCHIVE_RESTIC_REPO snapshots
        case '' backup
            restic -r $ARCHIVE_RESTIC_REPO backup $archives --tag archives
        case '*'
            echo "usage: archbackup [snapshots]" >&2
            return 1
    end
end
