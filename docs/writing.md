# Writing: Pandoc, Neovim, and the research workflow

This setup is tuned for academic / long-form writing in Markdown: draft in
Neovim, cite from Zotero, lint with Vale, and export to HTML/PDF/docx with
Pandoc. This page covers each layer, then the
[reading workflow](#reading-workflow-vault--website) that ties the Zotero
library, the Obsidian vault, and the website together.

## Prose and Pandoc

### Style linting (Vale)

`vale` flags style problems (wordiness, clichés, passive voice) as you write;
Neovim runs it automatically on Markdown files. `make vale` sets it up: it
writes a global `~/.vale.ini` and downloads four rule packages — `proselint`,
`write-good`, `Readability`, and `alex`.

Only `Vale` + `proselint` actually run globally. The other three misfire on
academic history (measured: 22 of 23 alerts on a typical paragraph were
noise), so they're per-project opt-ins — run `valeinit` in a project to
scaffold a local `.vale.ini`, then enable what fits (e.g. `Readability` for
syllabi). A per-project `.vale.ini` always overrides the global one.

Division of labor: Vale owns *style*, vim's built-in spell owns *spelling*
(`Vale.Spelling` is off), and `harper_ls` owns *grammar*.

The **`Academic` vocabulary** (`writing/vale/vocab/Academic/`) is the shared
allowlist — proper nouns, historiographical/archival terms, and tool names
that no spelling or terminology rule should flag. It's tracked in the repo and
symlinked into place by `make vale`, so additions sync across machines.

### Templates (`writing/pandoc/`)

- `metadata.yaml.tmpl` — the document metadata block (title, author,
  `bibliography`, page geometry, font size, line spacing). Run `newmeta` in the
  folder holding the document to render a copy:
  ```fish
  newmeta
  ```
  Do **not** copy the template by hand. Pandoc does not expand `~` in document
  metadata, so a hand-copied `csl: ~/…` line fails with "not found in resource
  path" and exit 99. `newmeta` substitutes the absolute paths and today's date,
  the same way `newdoc` does for frontmatter.

  Its `bibliography` points at the Better CSL JSON export (`Library.json`),
  not the `.bib` — CSL JSON preserves Zotero's archive / archive-location
  fields that BibTeX drops, so archival citations render with repository and
  box/folder. Better BibTeX keeps both files auto-exported.
- `defaults.yaml` — the shared Pandoc pipeline (pandoc-crossref → citeproc),
  used by both the nvim `<leader>p` exports and `mdexport`. It deliberately
  does *not* set a CSL style — a defaults-file `csl` would override document
  frontmatter and silently re-style manuscripts pinned to an older edition.
- `chicago-notes-bibliography-18th-edition.csl` — the current CMOS (the
  default for `newdoc` and `metadata.yaml`).
- `chicago-notes-bibliography-17th-edition.csl` — kept for in-progress
  manuscripts and journals still on 17e; point a document's `csl:`
  frontmatter at it.
- `vale-project.ini` — the per-project Vale config template (what `valeinit`
  copies).

### Export

Export with `<leader>ph` (HTML), `<leader>pp` (PDF), or `<leader>pd` (docx)
inside Neovim — or `mdexport` from the shell. All of them:

- run the shared pipeline from `writing/pandoc/defaults.yaml`
  (pandoc-crossref → citeproc, so cross-references resolve *before*
  citations),
- `cd` into the document's own directory first, so relative paths in
  `metadata.yaml` (bibliography, CSL) and relative images resolve correctly,
- automatically use a sibling `metadata.yaml` when one exists.

PDF export uses **tectonic** (set in `defaults.yaml`): a self-contained
LaTeX engine that downloads packages on demand — nothing to install or
maintain. The first PDF build fetches what it needs; later builds work
offline. Same engine the CV and syllabi repos use.

Markdown also renders live inside Neovim via `render-markdown.nvim`, so
headings, emphasis, and lists look styled while you edit.

---

## Neovim

A lean, **prose-first** Neovim config built on `lazy.nvim`. The emphasis is
fast startup (almost everything is lazy-loaded), Markdown/Pandoc authoring, and
just enough LSP for the languages used in `bin/` (Lua, Python, Bash) plus
grammar checking in prose (`harper_ls`).

**Leader key:** `,` (comma)

### Layout

```
writing/nvim/
├── init.lua                 # loads the modules below
├── lazy-lock.json           # pinned plugin commits (committed for reproducibility)
└── lua/
    ├── config/
    │   ├── options.lua      # editor options
    │   ├── keymaps.lua      # global key mappings
    │   ├── autocmds.lua     # filetype + focus autocommands
    │   └── lazy.lua         # bootstraps lazy.nvim
    └── plugins/
        ├── ui.lua           # nord theme + lualine
        ├── editor.lua       # oil, telescope (+bibtex), treesitter, gitsigns, fugitive
        ├── completion.lua   # blink.cmp
        ├── lsp.lua          # lspconfig + conform (formatting)
        ├── linting.lua      # nvim-lint (vale)
        ├── markdown.lua     # render-markdown
        └── writing.lua      # zen-mode, twilight, mini.nvim
```

### Key mappings

The leader is `,`. **Press it and wait** — `which-key` shows what can follow,
built from these same descriptions, so these tables are a reference rather
than something to memorize. `,?` lists every mapping including the plugins'.

**Navigation & editing**

| Keys          | Mode   | Action                                              |
|---------------|--------|-----------------------------------------------------|
| `<leader>w`   | Normal | Write (save) the buffer                             |
| `<leader>q`   | Normal | Quit the window                                     |
| `<leader>ff`  | Normal | Telescope **f**ind **f**iles                        |
| `<leader>fg`  | Normal | Telescope live **g**rep                             |
| `<leader>fb`  | Normal | Telescope **b**uffers                               |
| `<leader>z`   | Normal | Toggle **Zen mode** (distraction-free writing)      |
| `-`           | Normal | Open **Oil** file browser in the current dir        |
| `<leader>cf`  | Normal | **C**onform **f**ormat the buffer                   |
| `<CR>`        | Insert | Confirm the selected completion item                |
| `,?`          | Normal | List every mapping                                  |

`j` and `k` move by *display* line, so they follow wrapped prose — but only
without a count. `10j` still moves ten real lines.

**Citations & bibliography**

| Keys          | Mode   | Action                                              |
|---------------|--------|-----------------------------------------------------|
| `<leader>fc`  | Normal | Telescope bibtex — insert `@citekey` **c**itation   |
| `<leader>fo`  | Normal | **O**pen the `@citekey` under the cursor in Zotero  |
| `<leader>fr`  | Normal | Open/create the **r**eading note for the citekey under the cursor |
| `<leader>pc`  | Normal | **C**heck `@citekey`s against the Zotero library    |

`<leader>pc` shells out to `bin/citecheck.py` (the same tool behind the fish
`citecheck` function) to validate every `@citekey`/`-@citekey` in the buffer
against the Zotero library before you export — an unresolved citekey exports
"successfully" with `smith2020?` in the text otherwise. `<leader>fr` closes
the same loop `zotcheck` reports on: with the cursor on `@smith2020`, it opens
that citekey's reading note if one exists, or scaffolds it with `readnote`
(metadata pulled from the Zotero library) and opens the result — `readnote`'s
own auto-open only fires when run interactively, so this opens it itself
rather than racing a second nvim.

**Archival research**

| Keys          | Mode   | Action                                              |
|---------------|--------|-----------------------------------------------------|
| `<leader>fa`  | Normal | Search OCR'd **a**rchival scans (`arch grep`)       |

Prompts for a query, searches the OCR text layer of every scan under
`$RESEARCH_ARCHIVES_DIR` (`arch grep` → ripgrep-all), and loads the hits into
the quickfix list as `file:page` entries. A PDF's raw bytes aren't something
nvim can usefully display, so a `BufReadCmd` autocmd (`autocmds.lua`)
intercepts `*.pdf` quickfix jumps and opens the scan in Preview instead of
loading it as a buffer — `<CR>` on a hit opens the source PDF in Preview; the
quickfix line still shows which page the match was on.

**Pandoc export & preview**

| Keys          | Mode   | Action                                              |
|---------------|--------|-----------------------------------------------------|
| `<leader>ph`  | Normal | Pandoc export → **H**TML (citeproc + crossref)      |
| `<leader>pp`  | Normal | Pandoc export → **P**DF (citeproc + crossref)       |
| `<leader>pd`  | Normal | Pandoc export → **d**ocx (uses `reference.docx`)    |
| `<leader>pv`  | Normal | Pre**v**iew in Marked 2 (live-updates on save)      |
| `<leader>pl`  | Normal | Check **l**inks in the buffer (`lychee`)            |
| `<leader>pa`  | Normal | **A**rchive every cited URL to the Wayback Machine (`mdarchive`) |

Exports run **asynchronously** (`vim.system`), so the editor stays responsive
during slow LaTeX builds, and the buffer is auto-written first. A
notification reports the result — including pandoc's own *warnings* on an
otherwise successful export, for the same unresolved-citekey case `<leader>pc`
catches ahead of time. `<leader>pl` and `<leader>pa` are the same pre-flight
idea applied to links instead of citations — check before you export or
publish, since link rot is silent until a reader hits it. `<leader>pa`
confirms first: archiving is slow (~30s+ per URL on a link-heavy piece).

**Blog publishing (site)**

| Keys          | Mode   | Action                                              |
|---------------|--------|-----------------------------------------------------|
| `<leader>bp`  | Normal | **P**ublish the current draft (`site publish --cite`) |
| `<leader>bc`  | Normal | Run the website pre**c**heck (`site check`)         |
| `<leader>bs`  | Normal | **S**hip the website repo — commit + push (`site ship`) |

These route to the `site` fish function (`~/git/website/scripts/`) rather
than calling those scripts directly, so behavior matches the shell workflow
exactly. Since `site` is a fish *function*, not something on `$PATH`, all
three shell out through `fish -c` instead of `vim.system` exec-ing it
directly. `<leader>bp` and `<leader>bs` confirm before running: publishing
deletes the draft from the vault, and shipping reaches the remote.
`<leader>bs` prompts for the commit message and passes `--yes`, since
`ship.sh`'s own interactive prompts would read from a closed stdin under
`vim.system` and abort as "Aborted".

**Git**

| Keys          | Mode   | Action                                              |
|---------------|--------|-----------------------------------------------------|
| `<leader>gs`  | Normal | Fugitive **g**it **s**tatus (stage/commit/diff)     |

**From `mini.nvim` (defaults):**

| Keys           | Action                                                        |
|----------------|---------------------------------------------------------------|
| `gcc`          | Toggle comment on the current line                            |
| `gc` + motion  | Toggle comment over a motion / visual selection               |
| `sa` + motion  | **S**urround **a**dd (e.g. `saiw"` wraps a word in quotes)    |
| `sd`           | **S**urround **d**elete (`sd"`)                               |
| `sr`           | **S**urround **r**eplace (`sr"'`)                             |
| (auto)         | `mini.pairs` auto-closes brackets/quotes                      |

### Notable options (`options.lua`)

| Option                         | Value             | Why                                              |
|--------------------------------|-------------------|--------------------------------------------------|
| `clipboard`                    | `unnamedplus`     | Yanks sync with the macOS clipboard / `pbpaste`  |
| `wrap` + `linebreak`           | on                | Soft-wrap prose at word boundaries               |
| `textwidth` / `colorcolumn`    | `80` / `81`       | Visual guide for prose width                     |
| `spell` (per-filetype)         | on for md/text    | Spell-check prose only, not code                 |
| `conceallevel`                 | `2` (md)          | Lets `render-markdown` hide syntax markers       |
| `undofile`                     | on                | Persistent undo across sessions                  |
| `updatetime` / `timeoutlen`    | `250` / `300` ms  | Snappy diagnostics + which-key-style timing      |
| `ignorecase` + `smartcase`     | on                | Case-insensitive search until you type a capital |

### Plugins

- **Theme/UI:** `gbprod/nord.nvim`, `lualine` (globalstatus), `which-key`
  (the leader menu — it reads the `desc` on each mapping, so adding a mapping
  with a description lists it automatically).
- **Navigation:** `telescope` (lazy on `:Telescope`), `oil` (`-`), `gitsigns`,
  `vim-fugitive` (`<leader>gs` for `:Git` status; stage/commit/diff from there).
- **Syntax:** `nvim-treesitter` (**`main` branch** — parsers install
  automatically on first launch; highlighting starts per-filetype).
- **Writing:** `render-markdown`, `zen-mode`, `twilight`, `mini.nvim`
  (`pairs`, `comment`, `surround`).
- **LSP:** `nvim-lspconfig` for `lua_ls`, `pyright`, `bashls`, `harper_ls`
  (grammar checking in Markdown — vale covers style, vim's built-in spell
  covers spelling, so harper's own SpellCheck linter is disabled), and
  `marksman` (cross-document Markdown navigation: go-to-definition on
  links/headings, link completion, rename across files). Loads only for those
  filetypes.
- **Completion:** `blink.cmp` (lsp + buffer + path + snippets sources, all
  built in — no separate source plugins) with the built-in `vim.snippet`
  expander; loads on `InsertEnter`. Enter confirms only an explicitly
  selected item. `snippets/markdown.json` provides pandoc-crossref snippets
  (`fig`, `tbl`, `eq`, `sec` — label syntax for figures/tables/equations/sections —
  plus `note` for self-numbering inline footnotes, the low-friction form for
  Chicago notes style).
- **Citations:** `telescope-bibtex` (`<leader>fc`) fuzzy-finds the Zotero
  Better BibTeX export (`~/Documents/Library/Library.bib`) and inserts a
  pandoc `@citekey`.
- **Formatting:** `conform.nvim` — `stylua` (Lua), `black` (Python),
  `prettier` (Markdown). Trigger with `<leader>cf`.
- **Linting:** `nvim-lint` runs `vale` on Markdown (read/save) — see
  [Prose and Pandoc](#prose-and-pandoc).

> **Plugin pins:** `lazy-lock.json` is committed so every machine gets the same
> plugin versions. To update all plugins to their latest commits, run `:Lazy update`
> inside Neovim, then commit the resulting `lazy-lock.json` change.

> All LSP servers, formatters, and linters are installed by the Brewfile
> (`lua-language-server`, `pyright`, `bash-language-server`, `harper`,
> `marksman`, `stylua`, `black`, `prettier`, `vale`) — there is no Mason layer.

> **Personal dictionary:** words added with `zg` write to
> `writing/nvim/spell/en.utf-8.add` (`spellfile` is pinned to the config dir),
> so the dictionary is version-controlled and syncs across machines. The
> compiled `.add.spl` binary is regenerated locally and gitignored.

---

## Writing functions and aliases (fish)

The writing-specific subset of `shell/fish/functions/` — autoloaded, call them
like commands. (General-purpose shell functions are listed under
[Shell → Functions](shell.md#functions-shellfishfunctions).)

| Function                | Usage / behavior                                                                      |
|-------------------------|---------------------------------------------------------------------------------------|
| `newdoc <file> [title]` | Create a Markdown file pre-filled with Pandoc metadata and open in Neovim             |
| `mdexport <fmt> <md…>`  | Batch Pandoc export (crossref + citeproc + sibling `metadata.yaml`); mirrors nvim `<leader>p`. Exits non-zero and repeats the warning if pandoc reports one — an unresolved citekey exports "as if fine" otherwise |
| `newmeta`               | Write a `metadata.yaml` into this folder with the paths and date filled in |
| `words <md…>`           | Prose word count via `pandoc -t plain` (excludes frontmatter/syntax/URLs)             |
| `cite`                  | fzf over the Zotero `.bib`; copies `@citekey` (warns if the export is >30 days stale) |
| `linkcheck [md…]`       | Check links with `lychee` (no args: all `*.md` under the cwd)                         |
| `mdarchive <md…>`       | Snapshot every URL cited in the file(s) to the Wayback Machine (lychee + `waybackup`) |
| `mdlinks <browser>`     | Markdown reference definitions for every open tab — `mdlinks safari` or `mdlinks firefox`. Writes to stdout, so `mdlinks firefox \| pbcopy` or `>> notes.md`. Strips `utm_*`/`ref` params and labels each link by domain (`[jstor]: https://…`) |
| `docx2md <docx> [mode]` | Convert returned `.docx` edits to markdown (`--track-changes`: all/accept/reject)     |
| `valeinit`              | Scaffold a per-project `.vale.ini` from `writing/vale/vale-project.ini`               |
| `pdfpages <pdf> <range>`| Extract a page range to a new PDF (`qpdf`)                                            |
| `pdfmerge <out> <in…>`  | Merge PDFs into one (`qpdf`)                                                          |
| `wordfrequency`         | Read stdin, print word counts sorted high→low (great for prose)                       |
| `arch grep <query>`     | Full-text search the OCR'd archival scans (`ripgrep-all`); prints matching page numbers |
| `arch ocr`              | List archival PDFs with no OCR text layer (run `ocrmypdf` on those)                    |
| `arch verify [update]`  | SHA-256 manifest of the scans; detects corruption / bit-rot                           |
| `arch backup [snapshots]`| `restic` versioned, encrypted snapshot of the archive to an external HD               |
| `citecheck <md…>`       | Validate every `@citekey` / `-@citekey` in a draft against `Library.json` before export |
| `zotcheck [--list]`     | Reconcile notes vs Zotero recursively — orphaned citekeys, and items lacking a note. Exits non-zero on orphans only (see [conventions](shell.md#conventions)) |
| `readnote <key> [--primary]` | Scaffold a history-oriented reading note for a Zotero citekey (metadata from `Library.json` + archival fields when present); closes a `zotcheck` gap |

**Bibliography sources.** Pandoc *rendering* (`newdoc`, `metadata.yaml`) reads
the Better CSL JSON export (`~/Documents/Library/Library.json`), which preserves
Zotero's archive / box-folder fields that BibTeX drops; the citekey *pickers*
(`cite`, telescope-bibtex) stay on `Library.bib` since they parse BibTeX syntax.
Better BibTeX keeps both auto-exported. The Obsidian Pandoc plugins use the same
CMOS 18e CSL, so in-app previews match final output.

**Archive integrity.** `arch grep` / `arch ocr` / `arch verify` / `arch backup`
operate on `~/Notes/03 Research/Archives` (the Obsidian vault, outside this repo)
— the functions live here, the irreplaceable scans live there.

**Workflow paths.** The personal locations these functions touch (Zotero
library, notes trees, research archives, website repo) are defined once in
[`paths.env`](../paths.env) (`ZOTERO_LIBRARY_JSON`, `READING_NOTES_DIR`,
`RESEARCH_ARCHIVES_DIR`, …) rather than hardcoded per function. Fish exports
from that file, and Neovim reads the same tracked values directly, so path
edits stay in one place. Per-machine `set -Ux` overrides still win. Neovim's
Telescope bibtex picker resolves the same tracked `ZOTERO_LIBRARY_BIB` path.

**Aliases**

| Alias    | Expands to                                                            |
|----------|-----------------------------------------------------------------------|
| `rgmd`   | `rg -t md` — search only markdown (named to avoid macOS's `mdfind`)   |
| `drafts` | Markdown files modified in the last 7 days (`fd` → `eza`, by mtime)   |
| `marked` | `open -a "Marked 2"` — preview (shell twin of nvim `<leader>pv`)      |

For revision review, `git wdiff` (abbr `gwd`) shows word-level diffs of prose —
see [Git → aliases](git.md#git-aliases).

---

## Reading workflow (vault ↔ website)

The reading pipeline connects three places: the Zotero library
(`Library.json`, exported by Better BibTeX), the Obsidian vault
(`~/Notes`, reading notes keyed by citekey), and the website repo
(`~/git/website`, whose `data/reading/` ledger renders the public reading
page). All logic for the website side lives in `$WEBSITE_REPO/scripts/`;
the `site` function (see [Shell → Functions](shell.md#functions-shellfishfunctions))
dispatches to those scripts from anywhere.

**Start a source (has a Zotero citekey):**

```sh
readnote smith2020               # add --primary for a primary source
site newsource zotero smith2020  # prefills the source page from the Zotero library
```

`readnote` scaffolds the vault note from the Zotero CSL-JSON export and opens it
in nvim; `site newsource zotero` creates the website's source page at
`content/sources/<slug>/_index.md`, prefilled from the same library. Each half
runs standalone — run `site newsource` alone if the vault note already exists.

**Start a source (no Zotero record — casual reading):**

```sh
site newsource book "Title"      # prefills from Open Library (ISBN) / Crossref (DOI)
site newsource article "Title"   # prefills from Crossref (DOI)
```

**Finish a source:**

```sh
site finishsource [slug]         # lists current sources if no slug
```

Flips the source page's `status` to `read`, stamps `finished`, and derives
`read_year`. With no slug it lists the sources currently marked `reading`. Pass
`--push` to run the website's preflight + commit + push in one step.

**Keep everything reconciled:**

```sh
zotcheck --list                  # orphaned notes + Zotero items with no note yet
citecheck draft.md               # every @citekey in a draft resolves in Library.json
```
