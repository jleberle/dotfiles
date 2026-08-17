# Source Serif 4 (static instances)

Static Regular/Bold/Italic/Bold Italic instances (wght 400/700, opsz 20 — the
family's own "text" optical size), generated from Adobe's Source Serif 4
variable font via `fonttools varLib.instancer`. SIL Open Font License 1.1
(see Adobe's upstream repo: https://github.com/adobe-fonts/source-serif).

## Why static, not the Homebrew cask

`brew install --cask font-source-serif-4` only ships the variable font
(`SourceSerif4[opsz,wght].ttf`). When that variable font is hand-applied to
text in Keynote (as opposed to being set programmatically), Keynote/PowerPoint
sometimes resolve it to a mangled named-instance string —
`"Source Serif 4 Regular Regular"` — instead of the clean family name. A run
stuck with that typeface fails to match any installed or embedded font by
name and silently substitutes on any machine, including the classroom one.
See `~/Documents/Classes/Slides/theme-system/README.txt`, "Fonts on the
classroom computer", for the full writeup (2026-08-17).

The `font-source-serif-4` cask was removed from `homebrew/brewfile` for this
reason; these static instances are the replacement, symlinked into
`~/Library/Fonts` by `make fonts`.

## Regenerating

If the variable font source is needed again (e.g. to instantiate a different
weight), reinstall the cask temporarily, then:

```
python3 -m venv /tmp/fonttools-venv && /tmp/fonttools-venv/bin/pip install fonttools
FT=/tmp/fonttools-venv/bin/fonttools
SRC="$(brew --caskroom)/font-source-serif-4/latest"

"$FT" varLib.instancer -o SourceSerif4-Regular.ttf \
  "$SRC/SourceSerif4[opsz,wght].ttf" wght=400 opsz=20 --update-name-table
"$FT" varLib.instancer -o SourceSerif4-Bold.ttf \
  "$SRC/SourceSerif4[opsz,wght].ttf" wght=700 opsz=20 --update-name-table
"$FT" varLib.instancer -o SourceSerif4-Italic.ttf \
  "$SRC/SourceSerif4-Italic[opsz,wght].ttf" wght=400 opsz=20 --update-name-table
"$FT" varLib.instancer -o SourceSerif4-BoldItalic.ttf \
  "$SRC/SourceSerif4-Italic[opsz,wght].ttf" wght=700 opsz=20 --update-name-table
```

Then `brew uninstall --cask font-source-serif-4` again — it's not a build
dependency, just a one-time source for the variable font.
