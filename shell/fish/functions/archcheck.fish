function archcheck --description 'Renamed to archocr — this stub only points at the new name'
    # `archcheck` was one of six unrelated commands ending in -check, and the one
    # thing it did NOT check was the archive (that is archverify) or the backup
    # (archbackup check). It is `archocr` now, which says what it looks for.
    #
    # This stub exists only so the old name fails with a pointer instead of
    # "unknown command". Delete it once the new name is habit.
    echo "archcheck: renamed to archocr (it looks for a missing OCR text layer)" >&2
    echo "        run: archocr" >&2
    return 1
end
