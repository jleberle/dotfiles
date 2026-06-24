function citecheck --description 'Check every @citekey in a draft exists in the Zotero CSL JSON export'
    # usage: citecheck <file.md> [more.md ...]
    # Catches broken pandoc citations (typos, deleted items, key drift) before
    # export — otherwise they render as "???" or silently vanish in the PDF.
    # Supports both normal @citekey and suppressed-author -@citekey forms.
    if test (count $argv) -eq 0
        echo "usage: citecheck <file.md> [more.md ...]" >&2
        return 1
    end
    set -l lib $ZOTERO_LIBRARY_JSON
    if not test -f $lib
        echo "citecheck: library not found: $lib — export Better CSL JSON from Zotero" >&2
        return 1
    end

    python3 -c '
import json, re, sys
ids = {i.get("id") for i in json.load(open(sys.argv[1]))}
cite = re.compile(r"(?:^|[\s\[;])-?@([A-Za-z0-9][\w:.#&+/-]*)")
bad = 0
for path in sys.argv[2:]:
    try:
        text = open(path).read()
    except OSError as e:
        print(f"citecheck: {e}", file=sys.stderr); continue
    keys = [m.group(1).rstrip(".") for m in cite.finditer(text)]
    missing = sorted({k for k in keys if k not in ids})
    if missing:
        bad += len(missing)
        print(f"{path}: {len(missing)} unknown citation(s):")
        for k in missing:
            print(f"  @{k}")
    else:
        print(f"{path}: OK ({len(set(keys))} citations, all resolve)")
sys.exit(1 if bad else 0)
' $lib $argv
end
