function zotcheck --description 'Reconcile reading/research notes against the Zotero library (orphans + missing notes)'
    # usage: zotcheck            summary: orphaned notes + count of items lacking a note
    #        zotcheck --list     also list every Zotero item that has no note yet
    #
    # Two failure modes this catches:
    #   - a note whose citekey is no longer in Zotero (key drifted or item
    #     deleted) — its [[links]] and @citations are now broken;
    #   - a Zotero item with no note — a source you have not processed.
    set -l lib $ZOTERO_LIBRARY_JSON
    if not test -f $lib
        echo "zotcheck: library not found: $lib" >&2
        return 1
    end

    python3 -c '
import json, os, re, sys
ids = {i.get("id") for i in json.load(open(sys.argv[1])) if i.get("id")}
show = "--list" in sys.argv
dirs = [d for d in sys.argv[2:] if os.path.isdir(d)]

notes = {}
for d in dirs:
    for root, _, files in os.walk(d):
        for fn in files:
            if not fn.endswith(".md"):
                continue
            path = os.path.join(root, fn)
            text = open(path).read()
            m = re.search(r"^citekey:\s*(\S+)", text, re.M)
            key = m.group(1).strip() if m else fn[:-3]
            notes[key] = os.path.relpath(path, d)

orphans = sorted(k for k in notes if k not in ids)
missing = sorted(i for i in ids if i not in notes)

if orphans:
    print(f"Notes whose citekey is NOT in Zotero ({len(orphans)}):")
    for k in orphans:
        print(f"  {k}  ({notes[k]})")
else:
    print("All note citekeys resolve to a Zotero item.")

print(f"\nZotero items with no note yet: {len(missing)}" + ("" if show else "  (zotcheck --list to see them)"))
if show:
    for k in missing:
        print(f"  {k}")
' $lib $READING_NOTES_DIR $RESEARCH_NOTES_DIR $argv
end
