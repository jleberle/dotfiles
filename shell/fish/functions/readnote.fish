function readnote --description 'Scaffold a reading note from a Zotero citekey (closes the zotcheck loop)'
    # usage: readnote <citekey> [--primary]
    # Creates <citekey>.md in $READING_NOTES_DIR with frontmatter pulled from the
    # Zotero CSL JSON export, in the exact shape zotcheck reconciles — so a
    # "Zotero item with no note yet" becomes a real note in one step. Defaults the
    # source tag to secondary; pass --primary for a primary source.
    argparse primary -- $argv
    or return 1

    if test (count $argv) -ne 1
        echo "usage: readnote <citekey> [--primary]" >&2
        return 1
    end

    # Accept @key or bare key.
    set -l key (string replace -r '^@' '' -- $argv[1])
    set -l source (set -q _flag_primary; and echo primary; or echo secondary)

    if not test -f $ZOTERO_LIBRARY_JSON
        echo "readnote: library not found: $ZOTERO_LIBRARY_JSON — export Better CSL JSON from Zotero" >&2
        return 1
    end
    if not test -d $READING_NOTES_DIR
        echo "readnote: reading-notes dir not found: $READING_NOTES_DIR" >&2
        return 1
    end

    set -l file $READING_NOTES_DIR/$key.md
    if test -e $file
        echo "readnote: note already exists: $file" >&2
        return 1
    end

    # Look up the key and write the note. Exits nonzero (no file created) if the
    # citekey isn't in the library, so we never scaffold an instant orphan.
    python3 -c '
import json, sys
key, source, libpath, outpath = sys.argv[1:5]
lib = json.load(open(libpath))
item = next((i for i in lib if i.get("id") == key), None)
if item is None:
    sys.exit("readnote: citekey not in library: " + key)

auth = []
for a in item.get("author", []):
    if a.get("literal"):
        auth.append(a["literal"])
    else:
        fam = a.get("family", "")
        giv = a.get("given", "")
        auth.append((fam + ", " + giv).strip(", "))
authors = "; ".join(auth)
title = item.get("title", "")
try:
    year = item.get("issued", {}).get("date-parts", [[""]])[0][0] or ""
except Exception:
    year = ""

J = lambda s: json.dumps(s, ensure_ascii=False)   # safe YAML double-quoted scalar
zot = "zotero://select/items/@" + key
with open(outpath, "w") as f:
    f.write(
        "---\n"
        "type: document\n"
        f"authors: {J(authors)}\n"
        f"title: {J(title)}\n"
        f"year: {year}\n"
        f"citekey: {key}\n"
        f"zotero: {J(zot)}\n"
        "status: unread\n"
        "project:\n"
        "tags:\n"
        "  - zotero\n"
        f"  - source/{source}\n"
        "---\n\n"
    )
' $key $source $ZOTERO_LIBRARY_JSON $file
    or return 1

    echo "readnote: created "(string replace $HOME '~' $file)
    nvim $file
end
