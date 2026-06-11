function cite --description 'Fuzzy-pick a citation from the BibTeX library; copies @citekey'
    # usage: cite
    # Shell-side sibling of the nvim <leader>fc telescope-bibtex binding —
    # for citing in email, BBEdit, or anywhere outside the editor.
    set -l bib ~/Documents/Library/Library.bib

    if not test -f $bib
        echo "cite: library not found: $bib" >&2
        echo "cite: export it from Zotero via Better BibTeX (keep updated)" >&2
        return 1
    end

    # Warn when the Better BibTeX auto-export looks stale (>30 days).
    set -l age_days (math -s0 \( (date +%s) - (stat -f %m $bib) \) / 86400)
    if test $age_days -gt 30
        echo "cite: warning: library last updated $age_days days ago — check Zotero's Better BibTeX auto-export" >&2
    end

    # BBT citekeys encode author+year+title words, so fuzzy-matching the key
    # alone works well; the preview shows the full entry for confirmation.
    set -l key (rg -o '^@\w+\{([^,]+),' -r '$1' $bib | \
        fzf --prompt='cite> ' --preview="grep -A 12 -F '{'{}',' '$bib'")
    or return 0 # cancelled

    if type -q pbcopy
        printf '@%s' $key | pbcopy
        echo "@$key copied to clipboard"
    else
        echo "@$key"
    end
end
