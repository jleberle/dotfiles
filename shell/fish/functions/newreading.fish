function newreading --description 'Start a Zotero-backed reading source: scaffold the vault note, then the website ledger entry'
    # usage: newreading <citekey> [book|article] [--primary]
    # Chains the two commands that are always paired for anything with a Zotero
    # citekey: `readnote` scaffolds the vault reading note, then `site sync-reading`
    # pulls bib data from Zotero + that note into a new data/reading/ ledger entry.
    # For sources without a Zotero record, use `site newsource` directly instead —
    # it prefills from Open Library/Crossref and never touches the vault.
    argparse primary -- $argv
    or return 1

    if test (count $argv) -lt 1 -o (count $argv) -gt 2
        echo "usage: newreading <citekey> [book|article] [--primary]" >&2
        return 1
    end

    set -l key (string replace -r '^@' '' -- $argv[1])
    set -l type $argv[2]

    set -l readnote_args $key
    set -q _flag_primary
    and set -a readnote_args --primary

    readnote $readnote_args
    or return 1

    site sync-reading $key $type
end
