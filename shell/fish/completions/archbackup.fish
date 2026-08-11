# Completions for `archbackup`. `backup` is the explicit form of the default
# (bare `archbackup` does the same thing) and appeared in no usage string and
# no doc — tab is now one of the two places it surfaces.

complete -c archbackup -f
complete -c archbackup -n __fish_is_first_token -a backup \
    -d 'Create a new snapshot (same as no argument)'
complete -c archbackup -n __fish_is_first_token -a snapshots \
    -d 'List existing snapshots'
complete -c archbackup -n __fish_is_first_token -a check \
    -d 'Verify repository integrity (restic check)'
