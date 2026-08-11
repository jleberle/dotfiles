function wordfrequency --description 'Count and sort word frequency from stdin'
    if __help_requested $argv
        echo "usage: <command> | wordfrequency   (reads stdin)"
        return 0
    end

    # Typed bare at a prompt this reads from the terminal, so it just sits
    # there looking frozen until you work out that Ctrl-D is what it wants.
    # The docs say "reads stdin", but the person who typed it bare is not
    # reading the docs at that moment.
    if isatty stdin
        echo "wordfrequency: reads stdin, so typed bare it would just sit there" >&2
        echo "        pipe something in: cat draft.md | wordfrequency | head -20" >&2
        return 1
    end

    awk '
       BEGIN { FS="[^a-zA-Z]+" } {
           for (i=1; i<=NF; i++) {
               word = tolower($i)
               # Skip empties from a leading/trailing delimiter (FS splits there).
               if (word != "") words[word]++
           }
       }
       END {
           for (w in words)
                printf("%3d %s\n", words[w], w)
       } ' | sort -rn
end
