#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." &&
    pwd
)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

cat >"$tmp_dir/Library.json" <<'JSON'
[
  {
    "id": "smith2020",
    "title": "Reconstructing the Atlantic Archive",
    "author": [{ "family": "Smith", "given": "Jane" }],
    "issued": { "date-parts": [[2020]] },
    "container-title": "Journal of Atlantic History",
    "URL": "https://example.com/smith2020"
  },
  {
    "id": "jones1999",
    "title": "Merchants and Manuscripts",
    "author": [{ "family": "Jones", "given": "Alex" }],
    "issued": { "date-parts": [[1999]] }
  },
  {
    "id": "archive1850",
    "title": "Letterbook of the Harbor Committee",
    "author": [{ "literal": "Harbor Committee" }],
    "issued": { "date-parts": [[1850]] },
    "archive": "Massachusetts Historical Society",
    "archive_collection": "Harbor Committee Papers",
    "archive_location": "Box 3, Folder 12",
    "archive-place": "Boston",
    "abstract": "Useful for municipal debates over shipping, labor, and harbor regulation."
  }
]
JSON

mkdir -p "$tmp_dir/reading/nested" "$tmp_dir/research/chapter1"

cat >"$tmp_dir/reading/nested/missing2022.md" <<'EOF_NOTE'
---
citekey: missing2022
---
EOF_NOTE

cat >"$tmp_dir/research/chapter1/smith2020.md" <<'EOF_NOTE'
---
citekey: smith2020
---
EOF_NOTE

cat >"$tmp_dir/draft.md" <<'EOF_DRAFT'
Smith makes the broader point @smith2020, while -@jones1999 supplies the compressed follow-up citation.
EOF_DRAFT

cat >"$tmp_dir/prelude.fish" <<EOF_FISH
set -gx DOTFILES_DIR "$repo_dir"
set -gx ZOTERO_LIBRARY_JSON "$tmp_dir/Library.json"
set -gx ZOTERO_LIBRARY_BIB "$tmp_dir/Library.bib"
set -gx READING_NOTES_DIR "$tmp_dir/reading"
set -gx RESEARCH_NOTES_DIR "$tmp_dir/research"
source "$repo_dir/shell/fish/functions/__help_requested.fish"
source "$repo_dir/shell/fish/functions/__need_path.fish"
source "$repo_dir/shell/fish/functions/citecheck.fish"
source "$repo_dir/shell/fish/functions/zotcheck.fish"
source "$repo_dir/shell/fish/functions/readnote.fish"
EOF_FISH

cat >"$tmp_dir/run-citecheck.fish" <<EOF_FISH
source "$tmp_dir/prelude.fish"
citecheck "$tmp_dir/draft.md"
EOF_FISH

cite_output=$(fish "$tmp_dir/run-citecheck.fish")
[[ $cite_output == *"OK (2 citations, all resolve)"* ]] || {
  echo "writing-check: citecheck did not count both normal and suppressed-author citations" >&2
  echo "$cite_output" >&2
  exit 1
}

cat >"$tmp_dir/run-zotcheck.fish" <<EOF_FISH
source "$tmp_dir/prelude.fish"
zotcheck --list
EOF_FISH

# This fixture has an orphan (missing2022), so a non-zero exit is the CORRECT
# result — commands here exit non-zero when they find something to fix. Capture
# the status rather than letting `set -e` abort on it.
zot_status=0
zot_output=$(fish "$tmp_dir/run-zotcheck.fish") || zot_status=$?
[[ $zot_status -eq 1 ]] || {
  echo "writing-check: zotcheck should exit 1 when it finds an orphaned note (got $zot_status)" >&2
  echo "$zot_output" >&2
  exit 1
}
[[ $zot_output == *"missing2022  (nested/missing2022.md)"* ]] || {
  echo "writing-check: zotcheck did not report the nested orphaned note" >&2
  echo "$zot_output" >&2
  exit 1
}
[[ $zot_output == *$'  jones1999\n  archive1850'* || $zot_output == *$'  archive1850\n  jones1999'* ]] || {
  echo "writing-check: zotcheck missing-note list did not include the unresolved Zotero items" >&2
  echo "$zot_output" >&2
  exit 1
}
[[ $zot_output != *"smith2020"* ]] || {
  echo "writing-check: zotcheck treated a nested note as missing" >&2
  echo "$zot_output" >&2
  exit 1
}

# The other half of that contract: a backlog is not a failure. The research tree
# alone has no orphan — only Zotero items still lacking a note — so this must
# exit 0. Without this case, "always exit 1" would pass the check above.
zot_clean_status=0
zot_clean_output=$("$repo_dir/bin/zotcheck.py" "$tmp_dir/Library.json" "$tmp_dir/research") \
  || zot_clean_status=$?
[[ $zot_clean_status -eq 0 ]] || {
  echo "writing-check: zotcheck should exit 0 when the only finding is a reading backlog (got $zot_clean_status)" >&2
  echo "$zot_clean_output" >&2
  exit 1
}

cat >"$tmp_dir/run-readnote.fish" <<EOF_FISH
source "$tmp_dir/prelude.fish"
readnote archive1850 --primary
EOF_FISH

readnote_output=$(fish "$tmp_dir/run-readnote.fish")
note_path="$tmp_dir/reading/archive1850.md"
[[ -f $note_path ]] || {
  echo "writing-check: readnote did not create the note file" >&2
  echo "$readnote_output" >&2
  exit 1
}

grep -Fq "## Historiography / Context" "$note_path" || {
  echo "writing-check: expanded readnote scaffold is missing the historiography section" >&2
  exit 1
}
grep -Fq "Useful for municipal debates over shipping, labor, and harbor regulation." "$note_path" || {
  echo "writing-check: readnote did not carry the abstract into the context scaffold" >&2
  exit 1
}
grep -Fq -- "- Repository: Massachusetts Historical Society" "$note_path" || {
  echo "writing-check: readnote did not include repository metadata" >&2
  exit 1
}
grep -Fq -- "- Collection: Harbor Committee Papers" "$note_path" || {
  echo "writing-check: readnote did not include collection metadata" >&2
  exit 1
}
grep -Fq -- "- Locator: Box 3, Folder 12" "$note_path" || {
  echo "writing-check: readnote did not include archival locator metadata" >&2
  exit 1
}
grep -Fq "  - source/primary" "$note_path" || {
  echo "writing-check: readnote did not preserve the primary-source tag" >&2
  exit 1
}

# mdlinks: the Firefox path decodes a mozLz4 session store using the hand-written
# LZ4 block decoder in bin/mdlinks.py. That decoder is the one piece here that
# could break silently — a wrong answer looks like "no tabs" rather than an
# error. An LZ4 block may legally be a single literals-only sequence, so a
# fixture can be built without an LZ4 compressor.
python3 - "$tmp_dir/session.jsonlz4" <<'EOF_PY'
import json
import pathlib
import sys


def mozlz4(payload):
    n = len(payload)
    if n < 15:
        token, ext = bytes([n << 4]), b""
    else:
        rem, run = n - 15, bytearray()
        while rem >= 255:
            run.append(255)
            rem -= 255
        run.append(rem)
        token, ext = bytes([0xF0]), bytes(run)
    return b"mozLz40\0" + n.to_bytes(4, "little") + token + ext + payload


session = {
    "windows": [
        {
            "tabs": [
                {"index": 1, "entries": [{"url": "https://www.jstor.org/stable/1234567"}]},
                # index points past the first entry: the tab navigated away from
                # about:newtab, and the CURRENT url is what should be listed.
                {
                    "index": 2,
                    "entries": [
                        {"url": "about:newtab"},
                        {"url": "https://github.com/gitleaks/gitleaks"},
                    ],
                },
                {"index": 1, "entries": [{"url": "about:newtab"}]},
            ]
        },
        {
            "tabs": [
                {"index": 1, "entries": [{"url": "https://github.com/yokoffing/Betterfox?utm_source=x"}]},
                {"index": 1, "entries": [{"url": "http://localhost:1313/posts/draft/"}]},
            ]
        },
    ]
}
pathlib.Path(sys.argv[1]).write_bytes(mozlz4(json.dumps(session).encode()))
EOF_PY

# One assertion covering the lot: both windows walked, `index` honoured over the
# tab's history, about: tabs skipped, utm_* stripped, duplicate hosts numbered
# across windows, a single-label host labelled at all (the Ruby emitted `[]`),
# and the whole thing sorted by label.
mdlinks_output=$("$repo_dir/bin/mdlinks.py" --firefox "$tmp_dir/session.jsonlz4")
read -r -d '' mdlinks_expected <<'EOF_EXPECT' || true
[github]: https://github.com/gitleaks/gitleaks
[github 2]: https://github.com/yokoffing/Betterfox
[jstor]: https://www.jstor.org/stable/1234567
[localhost]: http://localhost:1313/posts/draft/
EOF_EXPECT
[[ $mdlinks_output == "$mdlinks_expected" ]] || {
  echo "writing-check: mdlinks did not render the Firefox session store as expected" >&2
  echo "--- got ---" >&2
  echo "$mdlinks_output" >&2
  echo "--- want ---" >&2
  echo "$mdlinks_expected" >&2
  exit 1
}

# The Safari path feeds the same renderer from stdin.
mdlinks_stdin=$(printf '%s\n' 'https://example.com/a?ref=x&keep=1' 'chrome://extensions' \
  | "$repo_dir/bin/mdlinks.py")
[[ $mdlinks_stdin == '[example]: https://example.com/a?keep=1' ]] || {
  echo "writing-check: mdlinks stdin path did not clean the URL as expected" >&2
  echo "$mdlinks_stdin" >&2
  exit 1
}

echo "writing-check: OK"
