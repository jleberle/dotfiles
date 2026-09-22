#!/usr/bin/env bash
set -euo pipefail

# Fixture test for bin/caskclassify.py, the thing that decides whether the
# weekly launchd job may upgrade a cask unattended. A bug here is not cosmetic:
# classifying an app cask as `auto` puts `brew upgrade --cask` back on a path
# with no terminal for its `sudo chgrp` and no App Management grant, which is
# exactly what left Bitwarden.app half-upgraded on 2026-09-21 (see CLAUDE.md).
#
# Runs offline. `--from-json` feeds the classifier a captured `brew info
# --json=v2` payload instead of shelling out, so CI needs no Homebrew.

repo_dir=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.." &&
    pwd
)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

cat >"$tmp_dir/casks.json" <<'JSON'
{"casks": [
  {"token": "font-plain",    "artifacts": [{"font": ["A.otf"]}, {"target": "x"}]},
  {"token": "cli-only",      "artifacts": [{"binary": ["tool"]}, {"manpage": ["tool.1"]}]},
  {"token": "completions",   "artifacts": [{"binary": ["t"]}, {"fish_completion": ["t.fish"]}]},
  {"token": "an-app",        "artifacts": [{"app": ["Thing.app"]}, {"zap": {}}]},
  {"token": "app-plus-cli",  "artifacts": [{"app": ["Big.app"]}, {"binary": ["big"]}]},
  {"token": "pkg-installer", "artifacts": [{"pkg": ["Thing.pkg"]}, {"uninstall": {}}]},
  {"token": "novel-kind",    "artifacts": [{"quantum_widget": ["W"]}]},
  {"token": "metadata-only", "artifacts": [{"zap": {}}, {"uninstall": {}}]}
]}
JSON

expect() { # expect <token> <expected line>
  local got
  got=$("$repo_dir/bin/caskclassify.py" --from-json "$tmp_dir/casks.json" "$1")
  [[ $got == "$2" ]] || {
    echo "cask-check: $1 classified wrong" >&2
    printf '  want: %q\n  got:  %q\n' "$2" "$got" >&2
    exit 1
  }
}

# Safe: nothing lands in /Applications, nothing needs sudo.
expect font-plain  "$(printf 'auto\tfont-plain')"
expect cli-only    "$(printf 'auto\tcli-only')"
expect completions "$(printf 'auto\tcompletions')"

# Unsafe: writes an app bundle, with or without safe artifacts alongside.
expect an-app       "$(printf 'manual\tan-app\tapp')"
expect app-plus-cli "$(printf 'manual\tapp-plus-cli\tapp')"
expect pkg-installer "$(printf 'manual\tpkg-installer\tpkg')"

# The allowlist's whole purpose: an artifact kind nobody has seen before is
# manual, not silently automated. If this ever flips to `auto`, SAFE has been
# turned into a denylist and the next new artifact type ships unattended.
expect novel-kind "$(printf 'manual\tnovel-kind\tquantum_widget')"

# A cask that installs nothing is unexpected, so it is manual too.
expect metadata-only "$(printf 'manual\tmetadata-only\tno-artifacts')"

# A token the payload does not mention at all — brew not knowing a cask must
# never read as "safe to upgrade".
expect ghost "$(printf 'manual\tghost\tunknown')"

# Order is the order asked for, so the caller can pair input with output.
multi=$("$repo_dir/bin/caskclassify.py" --from-json "$tmp_dir/casks.json" an-app font-plain ghost)
[[ $multi == "$(printf 'manual\tan-app\tapp\nauto\tfont-plain\nmanual\tghost\tunknown')" ]] || {
  echo "cask-check: multi-token output order or content wrong" >&2
  echo "$multi" >&2
  exit 1
}

echo "cask-check: OK"
