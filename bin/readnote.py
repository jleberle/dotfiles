#!/usr/bin/env python3
# Logic extracted from the `readnote` fish function (shell/fish/functions/readnote.fish)
# so it can be tested and edited without quoting through a shell string.
import json
import sys


def first_value(item, *names):
    for name in names:
        value = item.get(name)
        if value not in (None, ""):
            return value
    return ""


def main(argv):
    if len(argv) < 5:
        print("usage: readnote.py <key> <source> <library.json> <outpath>", file=sys.stderr)
        return 1

    key, source, libpath, outpath = argv[1:5]
    lib = json.load(open(libpath))
    item = next((i for i in lib if i.get("id") == key), None)
    if item is None:
        print(f"readnote: citekey not in library: {key}", file=sys.stderr)
        return 1

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

    container = first_value(item, "container-title")
    archive = first_value(item, "archive")
    archive_collection = first_value(item, "archive_collection", "archive-collection")
    archive_location = first_value(item, "archive_location", "archive-location")
    archive_place = first_value(item, "archive-place", "archive_place")
    url = first_value(item, "URL")
    abstract = first_value(item, "abstract")

    def J(s):
        return json.dumps(s, ensure_ascii=False)  # safe YAML double-quoted scalar

    zot = "zotero://select/items/@" + key
    evidence = []
    if archive:
        evidence.append(f"- Repository: {archive}")
    if archive_collection:
        evidence.append(f"- Collection: {archive_collection}")
    if archive_location:
        evidence.append(f"- Locator: {archive_location}")
    if archive_place:
        evidence.append(f"- Place: {archive_place}")
    if container:
        evidence.append(f"- Container / series: {container}")
    if url:
        evidence.append(f"- URL: {url}")
    if not evidence:
        evidence.append("- Repository / collection:")
        evidence.append("- Locator / pages:")

    context = [abstract] if abstract else [
        "- Position this source in the historiography, archive, or primary-source context."
    ]
    context_block = "\n".join(context)
    evidence_block = "\n".join(evidence)
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
            "## Summary\n\n"
            "## Argument / Content\n\n"
            "## Historiography / Context\n\n"
            + context_block
            + "\n\n"
            "## Evidence / Archival Notes\n"
            + evidence_block
            + "\n\n"
            "## Key Quotations\n"
            "- p. :\n\n"
            "## Project Use\n"
            "- Claim:\n"
            "- Chapter / section:\n\n"
            "## Follow-up\n"
            "- [ ]\n"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
