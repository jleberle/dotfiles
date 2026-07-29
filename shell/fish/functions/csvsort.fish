function csvsort --description 'Sort CSVs in a directory by the last word of the first field'
    # usage: csvsort [dir] [--header] [--force]   (no dir: the cwd)
    # Surname order for name-first CSVs: prepends the last space-separated word
    # of column 1 as a sort key, sorts case-insensitively, drops the key again.
    # Only files that are *not* already in that order are rewritten, to
    # <name>-sorted.csv; originals are never touched. Previously generated
    # *-sorted.csv files are skipped, so re-running is idempotent.
    #
    # Field 1 is split on plain commas — a quoted first field containing a comma
    # ("Smith, Jr., John") will key off the wrong text.
    argparse header force -- $argv
    or return 1

    if test (count $argv) -gt 1
        echo "usage: csvsort [dir] [--header] [--force]" >&2
        return 1
    end

    set -l dir .
    if test (count $argv) -eq 1
        set dir $argv[1]
    end

    if not test -d $dir
        echo "csvsort: no such directory: $dir" >&2
        return 1
    end

    # Non-matching glob expands to nothing in `set` (no error).
    set -l sources
    for file in $dir/*.csv
        string match -q '*-sorted.csv' -- $file; or set -a sources $file
    end

    if test (count $sources) -eq 0
        echo "csvsort: no CSV files in $dir" >&2
        return 1
    end

    # With --header, line 1 is copied through untouched and the sort starts at 2.
    set -l first_row 1
    if set -q _flag_header
        set first_row 2
    end

    set -l written 0
    for file in $sources
        set -l name (path basename $file)
        set -l out (string replace -r -- '\.csv$' '-sorted.csv' $file)
        set -l tmp (mktemp -t csvsort)

        if set -q _flag_header
            head -n 1 $file >$tmp
        end
        tail -n +$first_row $file \
            | awk -F',' '{n = split($1, a, " "); print a[n] "," $0}' \
            | sort -t',' -f \
            | cut -d',' -f2- >>$tmp

        # Nothing to do if the source is already in order, or if a previous run
        # already produced this exact output.
        if not set -q _flag_force
            if cmp -s $file $tmp; or cmp -s $out $tmp 2>/dev/null
                rm -f $tmp
                continue
            end
        end

        # cat (not mv) so the new file lands with the usual umask, not mktemp's 0600.
        cat $tmp >$out
        or begin
            rm -f $tmp
            return 1
        end
        rm -f $tmp

        echo "csvsort: $name → "(path basename $out)
        set written (math $written + 1)
    end

    if test $written -eq 0
        echo "csvsort: all "(count $sources)" file(s) already sorted"
    end
end
