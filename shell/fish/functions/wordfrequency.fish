function wordfrequency --description 'Count and sort word frequency from stdin'
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
