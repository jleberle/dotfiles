#!/usr/bin/env python3
# Logic extracted from the `citecheck` fish function (shell/fish/functions/citecheck.fish)
# so it can be tested and edited without quoting through a shell string.
import json
import re
import sys

CITE_RE = re.compile(r"(?:^|[\s\[;])-?@([A-Za-z0-9][\w:.#&+/-]*)")


def main(argv):
    if len(argv) < 2:
        print("usage: citecheck.py <library.json> <file.md> [more.md ...]", file=sys.stderr)
        return 1

    lib_path, *paths = argv[1:]
    ids = {item.get("id") for item in json.load(open(lib_path))}

    bad = 0
    for path in paths:
        try:
            text = open(path).read()
        except OSError as e:
            print(f"citecheck: {e}", file=sys.stderr)
            continue
        keys = [m.group(1).rstrip(".") for m in CITE_RE.finditer(text)]
        missing = sorted({k for k in keys if k not in ids})
        if missing:
            bad += len(missing)
            print(f"{path}: {len(missing)} unknown citation(s):")
            for k in missing:
                print(f"  @{k}")
        else:
            print(f"{path}: OK ({len(set(keys))} citations, all resolve)")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
