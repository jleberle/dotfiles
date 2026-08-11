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

zot_output=$(fish "$tmp_dir/run-zotcheck.fish")
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

echo "writing-check: OK"
