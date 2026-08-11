#!/usr/bin/env python3
"""Markdown reference-link definitions for a list of browser tabs.

Logic extracted from the two `md - Links - * Tabs` Automator Services (Brett
Terpstra's Markdown Service Tools) so it can be linted and tested like the rest
of bin/. Those kept ~90 lines of Ruby each INSIDE a .workflow plist, where
`git diff` showed an opaque blob and no `make lint-*` target could reach them —
which is how both of the bugs noted below survived for years unseen.

Two input modes, because the browsers expose their tabs completely differently:

    mdlinks.py                     URLs on stdin, one per line. Safari has a
                                   real AppleScript dictionary, so the fish
                                   wrapper collects them and pipes them here.
    mdlinks.py --firefox SESSION   Read Firefox's sessionstore recovery.jsonlz4
                                   directly. Firefox exposes NO AppleScript tab
                                   list, which is why the Ruby original drove it
                                   by synthesising ⌘L / ⌘C keystrokes sixty times
                                   with half-second delays — needing an
                                   Accessibility grant and clobbering the
                                   clipboard. Reading the session store needs
                                   neither, sees every window rather than the
                                   front one, and takes milliseconds.

Output is a block of Markdown reference definitions, sorted by label:

    [github]: https://github.com/gitleaks/gitleaks
    [github 2]: https://github.com/yokoffing/Betterfox
    [jstor]: https://www.jstor.org/stable/1234567

Two bugs in the Ruby originals are fixed here rather than reproduced:
  * A single-label host (`http://localhost:1313/`, i.e. anything served by
    `site serve`) fell into a `when 1` branch with no value, so the label came
    out nil and the line rendered as `[]: http://...`.
  * A non-http tab (`about:newtab`, which Firefox almost always has open) made
    the domain regex return nil, and the next line indexed it — a hard crash.
    Non-http(s) tabs are skipped here.

Behaviour deliberately dropped, both one-liners to restore if ever wanted:
  * An `itunes.apple.com` special case that matched `http://` only. That host
    became apps.apple.com years ago, so the branch was already dead.
  * A skip for workona.com session URLs, specific to a tool not used here.
"""

import argparse
import json
import re
import sys

MOZ_MAGIC = b"mozLz40\0"
HOST_RE = re.compile(r"^https?://([^/?#]+)", re.I)
TRACKING_RE = re.compile(r"^(?:utm_[^=]*|ref)=", re.I)


def lz4_block_decompress(src: bytes, expected: int) -> bytes:
    """Decode a raw LZ4 block (no frame header).

    Firefox stores its session as "mozLz4": the 8-byte magic above, a
    little-endian uint32 of the decompressed size, then a bare LZ4 block. Python
    ships no lz4 module and the block format is both tiny and frozen (it has not
    changed since 2011), so it is decoded here rather than taking a third-party
    dependency for thirty lines of work.

    The format is a run of sequences, each: a token byte whose high nibble is
    the literal count and low nibble the match length; that many literal bytes;
    then a 2-byte little-endian offset pointing backwards into the output, and
    a match of (low nibble + 4) bytes copied from there. A nibble of 15 means
    "add the following bytes until one is not 255". The final sequence is
    literals only and stops early.
    """
    out = bytearray()
    i, n = 0, len(src)

    while i < n:
        token = src[i]
        i += 1

        literals = token >> 4
        if literals == 15:
            while True:
                byte = src[i]
                i += 1
                literals += byte
                if byte != 255:
                    break
        out += src[i : i + literals]
        i += literals

        # Final sequence carries literals and no match.
        if i >= n:
            break

        offset = src[i] | (src[i + 1] << 8)
        i += 2
        if offset == 0:
            raise ValueError("corrupt LZ4 block: zero match offset")

        match = token & 0x0F
        if match == 15:
            while True:
                byte = src[i]
                i += 1
                match += byte
                if byte != 255:
                    break
        match += 4

        start = len(out) - offset
        if start < 0:
            raise ValueError("corrupt LZ4 block: match points before the output")
        # Byte at a time, deliberately: matches are allowed to overlap the
        # region still being written (that is how LZ4 encodes runs), so a slice
        # copy would read stale bytes.
        for k in range(match):
            out.append(out[start + k])

    if expected is not None and len(out) != expected:
        raise ValueError(
            f"LZ4 size mismatch: header claims {expected} bytes, decoded {len(out)}"
        )
    return bytes(out)


def read_firefox_session(path: str) -> list[str]:
    """Return the current URL of every tab in every window of a session store."""
    with open(path, "rb") as handle:
        raw = handle.read()

    if not raw.startswith(MOZ_MAGIC):
        raise ValueError(f"not a mozLz4 session store (bad magic): {path}")

    expected = int.from_bytes(raw[8:12], "little")
    session = json.loads(lz4_block_decompress(raw[12:], expected))

    urls = []
    for window in session.get("windows", []):
        for tab in window.get("tabs", []):
            entries = tab.get("entries", [])
            # `index` is 1-based and points at the entry currently shown; the
            # rest of the list is that tab's back/forward history.
            index = tab.get("index", len(entries))
            if entries and 1 <= index <= len(entries):
                url = entries[index - 1].get("url", "")
                if url:
                    urls.append(url)
    return urls


def strip_tracking(url: str) -> str:
    """Drop utm_* and ref query parameters, keeping everything else."""
    head, sep, query = url.partition("?")
    if not sep:
        return url
    kept = [p for p in query.split("&") if p and not TRACKING_RE.match(p)]
    return head + ("?" + "&".join(kept) if kept else "")


def label_for(url: str) -> str:
    """Short, stable reference label derived from the host.

    example.com -> example | www.example.com -> example | localhost -> localhost
    """
    match = HOST_RE.match(url)
    if not match:
        return "link"

    host = match.group(1).rpartition("@")[2]  # drop any user:pass@
    base, sep, port = host.rpartition(":")
    if sep and port.isdigit():
        host = base

    parts = host.split(".")
    if len(parts) >= 3:
        return parts[1]
    if len(parts) == 2:
        return parts[0]
    return host


def unique(label: str, taken: set) -> str:
    """`github`, then `github 2`, `github 3`, ... for repeated hosts."""
    if label not in taken:
        return label
    n = 2
    while f"{label} {n}" in taken:
        n += 1
    return f"{label} {n}"


def render(urls) -> list[str]:
    taken: set = set()
    pairs = []
    for url in urls:
        url = url.strip()
        if not HOST_RE.match(url):
            continue  # about:newtab, chrome://, file:// — nothing to cite
        url = strip_tracking(url)
        label = unique(label_for(url), taken)
        taken.add(label)
        pairs.append((label, url))

    pairs.sort(key=lambda pair: (pair[0].casefold(), pair[1]))
    return [f"[{label}]: {url}" for label, url in pairs]


def main(argv) -> int:
    parser = argparse.ArgumentParser(
        prog="mdlinks.py",
        description="Markdown reference-link definitions for open browser tabs.",
    )
    parser.add_argument(
        "--firefox",
        metavar="SESSION",
        help="path to Firefox's sessionstore-backups/recovery.jsonlz4",
    )
    args = parser.parse_args(argv[1:])

    try:
        if args.firefox:
            urls = read_firefox_session(args.firefox)
        else:
            urls = sys.stdin.read().splitlines()
    except (OSError, ValueError, json.JSONDecodeError) as err:
        print(f"mdlinks: {err}", file=sys.stderr)
        return 1

    lines = render(urls)
    if not lines:
        print("mdlinks: no http(s) tabs found", file=sys.stderr)
        return 0

    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
