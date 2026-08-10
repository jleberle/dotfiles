#!/usr/bin/env bash
# Keeps the "R2-D2" flash drive current with PowerPoint + PDF copies of every
# lecture deck edited natively as .key in the local Slides archive folder.
#
# Source of truth is the .key file (no export-on-every-save needed in Keynote);
# this script does the export + copy, triggered by the org.jaredeberle.decksync
# LaunchAgent watching /Volumes so it runs the moment the "R2-D2" drive is
# plugged in (see keynote/org.jaredeberle.decksync.plist beside this file,
# installed by `make decksync`). Safe to run any time by hand too -- it's
# idempotent, only touching files whose source is newer than what's already on
# the drive.
#
# This script lives in the dotfiles repo (keynote/) and is run from there by
# DeckSync.app. It used to live in ~/Documents/Classes/Slides/theme-system/,
# which meant `make decksync` on a new machine installed a LaunchAgent pointing
# at a file that did not exist -- the install succeeded, `doctor` reported the
# agent loaded, and every volume mount failed silently into the log. Course
# CONTENT still lives under ~/Documents/Classes/Slides; only this tooling moved.
#
# For each course, next to the .pptx copies it writes a PDF/ subfolder holding a
# PDF of every deck. The PDF is the font-independent backup: a PDF always embeds
# its own fonts, so it renders correctly on any classroom machine, whereas a
# .pptx relies on that machine having IBM Plex Sans / Source Serif 4 installed.
# For a .key deck both the .pptx and the PDF come from a single Keynote open.
#
# Any other subfolder beside a course's decks (audio/video the lecture plays
# from directly, e.g. "3980 - 15 Songs/Music/" or "3793 - Native History/
# Videos/") is mirrored to the drive as-is via rsync, skipping files that are
# already up to date so large media isn't re-copied every run. theme-system/
# (tooling, not course content) and PDF/ (this script's own export
# destination) are the only subfolders excluded.
#
# Courses are AUTO-DISCOVERED: every top-level folder in the Slides archive
# named "<4-digit number> ..." is synced, EXCEPT any tagged Online (name
# contains "Online", e.g. "1483 - Online"). New courses enroll automatically;
# there is no list to maintain. (theme-system/ itself, and the shared "00
# Master - Lecture Hall Dark Theme.key" beside it, don't match the 4-digit
# pattern and are intentionally not synced as a "course".)
#
# SOURCE_DOCS points at a plain local folder (~/Documents/Classes/Slides), not
# iCloud's Keynote Documents folder -- deliberately: an iCloud sync race on a
# folder living under Keynote's iCloud Documents directory has previously
# caused a "finished, lint-clean" .key to silently lose its last slide after
# save (see theme-system/README.txt's engine dev log). Keeping the working
# archive as a plain local folder avoids that failure mode; this script's job
# is exporting FROM that local archive TO the external drive, a separate copy
# step from iCloud sync entirely.
#
# Paths can be overridden by environment (for testing); production runs via the
# LaunchAgent set nothing, so the defaults below are used.
set -uo pipefail

DRIVE_NAME="${SLIDES_DRIVE_NAME:-R2-D2}"
DRIVE="${SLIDES_DRIVE:-/Volumes/$DRIVE_NAME}"
SOURCE_DOCS="${SOURCE_DOCS:-$HOME/Documents/Classes/Slides}"
LOG="${DECK_SYNC_LOG:-$HOME/Library/Logs/deck-sync.log}"

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG"; }

# No-op unless the R2-D2 drive is actually mounted.
if [ ! -d "$DRIVE" ]; then
  exit 0
fi

updated=0

# Open a .key once and export BOTH the PowerPoint copy and the PDF backup.
export_key() {
  local key_path="$1" out_pptx="$2" out_pdf="$3"
  osascript <<APPLESCRIPT >> "$LOG" 2>&1
tell application "Keynote"
  set theDoc to open POSIX file "$key_path"
  export theDoc to POSIX file "$out_pptx" as Microsoft PowerPoint
  export theDoc to POSIX file "$out_pdf" as PDF
  close theDoc saving no
end tell
APPLESCRIPT
}

# Export just a PDF backup from a plain .pptx (legacy decks not yet .key).
export_pptx_pdf() {
  local pptx_path="$1" out_pdf="$2"
  osascript <<APPLESCRIPT >> "$LOG" 2>&1
tell application "Keynote"
  set theDoc to open POSIX file "$pptx_path"
  export theDoc to POSIX file "$out_pdf" as PDF
  close theDoc saving no
end tell
APPLESCRIPT
}

# Auto-discover course folders: "<4 digits> ..." under the Slides archive
# folder, skipping any Online section.
while IFS= read -r -d '' src; do
  course="$(basename "$src")"
  case "$course" in *[Oo]nline*) continue ;; esac

  dst="$DRIVE/$course"
  pdf_dir="$dst/PDF"
  mkdir -p "$dst"

  # .key decks (the primary case): export .pptx + PDF if either is missing or
  # older than the .key.
  while IFS= read -r -d '' key; do
    base="$(basename "$key" .key)"
    case "$base" in *"pre-fix backup"*) continue ;; esac
    target="$dst/$base.pptx"
    pdf_target="$pdf_dir/$base.pdf"
    if [ ! -e "$target" ] || [ "$key" -nt "$target" ] \
       || [ ! -e "$pdf_target" ] || [ "$key" -nt "$pdf_target" ]; then
      mkdir -p "$pdf_dir"
      if export_key "$key" "$target" "$pdf_target"; then
        updated=$((updated + 1))
        log "exported: $course/$base.key -> $base.pptx + PDF/$base.pdf"
      else
        log "FAILED export: $course/$base.key"
      fi
    fi
  done < <(find "$src" -maxdepth 1 -name "*.key" -print0)

  # Plain .pptx decks not yet converted to .key: copy the .pptx if newer and
  # make a PDF backup from it -- but only when no .key of the same name exists
  # (the .key always wins and already produced both above).
  while IFS= read -r -d '' pptx; do
    base="$(basename "$pptx" .pptx)"
    case "$base" in *"pre-fix backup"*) continue ;; esac
    [ -e "$src/$base.key" ] && continue
    target="$dst/$base.pptx"
    pdf_target="$pdf_dir/$base.pdf"
    if [ ! -e "$target" ] || [ "$pptx" -nt "$target" ]; then
      cp "$pptx" "$target" && { updated=$((updated + 1)); log "copied: $course/$base.pptx"; }
    fi
    if [ ! -e "$pdf_target" ] || [ "$pptx" -nt "$pdf_target" ]; then
      mkdir -p "$pdf_dir"
      if export_pptx_pdf "$pptx" "$pdf_target"; then
        log "pdf: $course/$base.pptx -> PDF/$base.pdf"
      else
        log "FAILED pdf: $course/$base.pptx"
      fi
    fi
  done < <(find "$src" -maxdepth 1 -name "*.pptx" -print0)

  # Course-specific supplementary media that isn't a slide deck at all (e.g.
  # Music/, Videos/) -- mirrored as a subfolder via rsync rather than the
  # find+export loops above, since these are opaque source files to copy
  # as-is, not decks to convert. -u (update) skips anything already at least
  # as new on the drive, so a folder of large audio/video files is only
  # re-copied on first sync or when a file actually changes.
  while IFS= read -r -d '' subdir; do
    name="$(basename "$subdir")"
    case "$name" in
      theme-system|PDF) continue ;;
    esac
    mkdir -p "$dst/$name"
    changes="$(rsync -au --exclude='.DS_Store' --out-format='%n' "$subdir"/ "$dst/$name"/ 2>>"$LOG" | grep -v '/$')"
    if [ -n "$changes" ]; then
      n=$(printf '%s\n' "$changes" | grep -c .)
      updated=$((updated + n))
      log "synced: $course/$name/ ($n file(s))"
    fi
  done < <(find "$src" -maxdepth 1 -mindepth 1 -type d -print0)

  # exFAT scatters AppleDouble "._name" sidecar files next to everything macOS
  # writes; harmless (Windows/PowerPoint ignore them) but they clutter the
  # drive. Sweep them from this course's drive folder after writing. Scoped to
  # the course folder, so nothing else on the drive is touched.
  find "$dst" -name '._*' -type f -delete 2>/dev/null || true
done < <(find "$SOURCE_DOCS" -maxdepth 1 -mindepth 1 -type d -name '[0-9][0-9][0-9][0-9] *' -print0)

log "sync run complete: $updated file(s) updated"

if [ "$updated" -gt 0 ]; then
  osascript -e "display notification \"$updated deck(s) exported (.pptx + PDF)\" with title \"$DRIVE_NAME drive synced\"" >/dev/null 2>&1
fi
