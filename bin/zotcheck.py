#!/usr/bin/env python3
# Logic extracted from the `zotcheck` fish function (shell/fish/functions/zotcheck.fish)
# so it can be tested and edited without quoting through a shell string.
import json
import os
import re
import sys


def main(argv):
    if len(argv) < 2:
        print("usage: zotcheck.py <library.json> <dir> [dir ...] [--list]", file=sys.stderr)
        return 1

    lib_path = argv[1]
    rest = argv[2:]
    show = "--list" in rest
    dirs = [d for d in rest if os.path.isdir(d)]

    ids = {item.get("id") for item in json.load(open(lib_path)) if item.get("id")}

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
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
