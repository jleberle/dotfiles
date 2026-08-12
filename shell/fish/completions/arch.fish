# Completions for `arch` (grep | ocr | verify | backup — merged from the
# formerly separate archgrep/archocr/archverify/archbackup functions).

complete -c arch -f
complete -c arch -n __fish_is_first_token -a grep -d "Full-text search the OCR'd archival scans"
complete -c arch -n __fish_is_first_token -a ocr -d 'List scans with no OCR text layer'
complete -c arch -n __fish_is_first_token -a verify -d 'Verify (or regenerate) the SHA-256 manifest'
complete -c arch -n __fish_is_first_token -a backup -d 'Snapshot, list, or check the restic backup'

# `arch verify update` — bare `verify` verifies; `update` regenerates the
# manifest. `--update` still works but is not offered here — completions
# should teach the current convention, not preserve the old one.
complete -c arch -n '__fish_seen_subcommand_from verify' -a update \
    -d 'Regenerate the SHA-256 manifest after adding or removing scans'

# `arch backup` — `backup` is the explicit form of the default (bare
# `arch backup` does the same thing).
complete -c arch -n '__fish_seen_subcommand_from backup' -a backup \
    -d 'Create a new snapshot (same as no argument)'
complete -c arch -n '__fish_seen_subcommand_from backup' -a snapshots \
    -d 'List existing snapshots'
complete -c arch -n '__fish_seen_subcommand_from backup' -a check \
    -d 'Verify repository integrity (restic check)'
