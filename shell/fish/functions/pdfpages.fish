function pdfpages --description 'Extract a page range from a PDF (qpdf)'
    # usage: pdfpages <in.pdf> <range> [out.pdf]
    # e.g.:  pdfpages reader.pdf 10-25        → reader-p10-25.pdf
    #        pdfpages scan.pdf 1,5-9 excerpt.pdf
    if __help_requested $argv
        echo "usage: pdfpages <in.pdf> <range> [out.pdf]"
        echo "       range examples: 7   10-25   1,5-9   z (last page)"
        return 0
    end

    __require pdfpages qpdf; or return 1

    if test (count $argv) -lt 2
        echo "usage: pdfpages <in.pdf> <range> [out.pdf]" >&2
        echo "       range examples: 7   10-25   1,5-9   z (last page)" >&2
        return 1
    end

    set -l in $argv[1]
    set -l range $argv[2]

    if not test -f "$in"
        echo "pdfpages: no such file: $in" >&2
        return 1
    end

    set -l out
    if test (count $argv) -ge 3
        set out $argv[3]
    else
        set out (path change-extension '' $in)"-p$range.pdf"
    end

    if test -e "$out"
        echo "pdfpages: refusing to overwrite existing $out" >&2
        return 1
    end

    qpdf $in --pages . $range -- $out
    and echo "Wrote $out"
end
