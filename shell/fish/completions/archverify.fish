# Completions for `archverify`. Bare `archverify` verifies; `update` regenerates
# the manifest. The old `--update` spelling still works but is not offered here —
# completions should teach the current convention, not preserve the old one.

complete -c archverify -f
complete -c archverify -n __fish_is_first_token -a update -d 'Regenerate the SHA-256 manifest after adding or removing scans'
