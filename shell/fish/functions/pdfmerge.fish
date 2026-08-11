function pdfmerge --description 'Merge PDFs into one (qpdf)'
    # usage: pdfmerge <out.pdf> <in1.pdf> <in2.pdf> [...]
    if __help_requested $argv
        echo "usage: pdfmerge <out.pdf> <in1.pdf> <in2.pdf> [...]"
        return 0
    end

    __require pdfmerge qpdf; or return 1

    if test (count $argv) -lt 3
        echo "usage: pdfmerge <out.pdf> <in1.pdf> <in2.pdf> [...]" >&2
        return 1
    end

    if test -e "$argv[1]"
        echo "pdfmerge: refusing to overwrite existing $argv[1]" >&2
        return 1
    end

    for in in $argv[2..-1]
        if not test -f "$in"
            echo "pdfmerge: no such file: $in" >&2
            return 1
        end
    end

    qpdf --empty --pages $argv[2..-1] -- $argv[1]
    and echo "Wrote $argv[1]"
end
