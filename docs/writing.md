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

- `metadata.yaml` — the document metadata block (title, author,
  `bibliography`, page geometry, font size, line spacing). Copy it next to a
  document and edit:
  ```sh
  cp ~/git/dotfiles/writing/pandoc/metadata.yaml .
  ```
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
        ├── editor.lua       # oil, telescope (+bibtex), treesitter, gitsigns
        ├── completion.lua   # blink.cmp
        ├── lsp.lua          # lspconfig + conform (formatting)
        ├── linting.lua      # nvim-lint (vale)
        ├── markdown.lua     # render-markdown
        └── writing.lua      # zen-mode, twilight, mini.nvim
```

### Key mappings

| Keys          | Mode   | Action                                              |
|---------------|--------|-----------------------------------------------------|
| `<leader>w`   | Normal | Write (save) the buffer                             |
| `<leader>q`   | Normal | Quit the window                                     |
| `<leader>ff`  | Normal | Telescope **f**ind **f**iles                        |
| `<leader>fg`  | Normal | Telescope live **g**rep                             |
| `<leader>fb`  | Normal | Telescope **b**uffers                               |
| `<leader>z`   | Normal | Toggle **Zen mode** (distraction-free writing)      |
| `-`           | Normal | Open **Oil** file browser in the current dir        |
| `<leader>fc`  | Normal | Telescope bibtex — insert `@citekey` **c**itation   |
| `<leader>cf`  | Normal | **C**onform **f**ormat the buffer                   |
| `<leader>ph`  | Normal | **P**andoc export → **H**TML (citeproc + crossref)  |
| `<leader>pp`  | Normal | **P**andoc export → **P**DF (citeproc + crossref)   |
| `<leader>pd`  | Normal | **P**andoc export → **d**ocx (uses `reference.docx`) |
| `<leader>pv`  | Normal | Pre**v**iew in Marked 2 (live-updates on save)      |
| `<CR>`        | Insert | Confirm the selected completion item                |

Pandoc exports run **asynchronously** (`vim.system`) — the editor stays
responsive during slow LaTeX builds; a notification reports success/failure.
The buffer is auto-written before export/preview.

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

- **Theme/UI:** `gbprod/nord.nvim`, `lualine` (globalstatus).
- **Navigation:** `telescope` (lazy on `:Telescope`), `oil` (`-`), `gitsigns`.
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
| `mdexport <fmt> <md…>`  | Batch Pandoc export (crossref + citeproc + sibling `metadata.yaml`); mirrors nvim `<leader>p` |
| `words <md…>`           | Prose word count via `pandoc -t plain` (excludes frontmatter/syntax/URLs)             |
| `cite`                  | fzf over the Zotero `.bib`; copies `@citekey` (warns if the export is >30 days stale) |
| `linkcheck [md…]`       | Check links with `lychee` (no args: all `*.md` under the cwd)                         |
| `mdarchive <md…>`       | Snapshot every URL cited in the file(s) to the Wayback Machine (lychee + `waybackup`) |
| `mdimport <docx> [mode]`| Convert returned `.docx` edits to markdown (`--track-changes`: all/accept/reject)     |
| `valeinit`              | Scaffold a per-project `.vale.ini` from `writing/vale/vale-project.ini`               |
| `pdfpages <pdf> <range>`| Extract a page range to a new PDF (`qpdf`)                                            |
| `pdfmerge <out> <in…>`  | Merge PDFs into one (`qpdf`)                                                          |
| `wordfrequency`         | Read stdin, print word counts sorted high→low (great for prose)                       |
| `archgrep <query>`      | Full-text search the OCR'd archival scans (`ripgrep-all`); prints matching page numbers |
| `archcheck`             | List archival PDFs with no OCR text layer (run `ocrmypdf` on those)                    |
| `archverify [--update]` | SHA-256 manifest of the scans; detects corruption / bit-rot                           |
| `archbackup [snapshots]`| `restic` versioned, encrypted snapshot of the archive to an external HD               |
| `citecheck <md…>`       | Validate every `@citekey` / `-@citekey` in a draft against `Library.json` before export |
| `zotcheck [--list]`     | Reconcile notes vs Zotero recursively — orphaned citekeys, and items lacking a note   |
| `readnote <key> [--primary]` | Scaffold a history-oriented reading note for a Zotero citekey (metadata from `Library.json` + archival fields when present); closes a `zotcheck` gap |
| `newreading <key> [type] [--primary]` | Start a Zotero-backed source in one step: `readnote`, then `site sync-reading` (vault note + website reading-ledger entry) |

**Bibliography sources.** Pandoc *rendering* (`newdoc`, `metadata.yaml`) reads
the Better CSL JSON export (`~/Documents/Library/Library.json`), which preserves
Zotero's archive / box-folder fields that BibTeX drops; the citekey *pickers*
(`cite`, telescope-bibtex) stay on `Library.bib` since they parse BibTeX syntax.
Better BibTeX keeps both auto-exported. The Obsidian Pandoc plugins use the same
CMOS 18e CSL, so in-app previews match final output.

**Archive integrity.** `archgrep` / `archcheck` / `archverify` / `archbackup`
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
newreading smith2020 book        # or: article; add --primary for a primary source
```

This runs `readnote smith2020` (scaffolds the vault note from Zotero CSL-JSON,
opens it in nvim), then `site sync-reading smith2020 book` (pulls the
bibliographic identity from Zotero + the note into a new
`data/reading/books/<slug>.yaml` ledger entry, prompting for reading-specific
fields). Each half also runs standalone — rerun `site sync-reading` alone if
the note already exists.

**Start a source (no Zotero record — casual reading):**

```sh
site newsource book "Title"      # prefills from Open Library (ISBN) / Crossref (DOI)
site newbook "Title"             # shorthand for the book case
```

**Finish a source:**

```sh
site finishsource [slug]         # or: site finishbook — lists current sources if no slug
```

Marks the ledger entry `read`, sets `finished`/`read_year`, and — via
`sync-vault-status.py` — flips the matching vault note's `status` to `read`,
so the vault and the public ledger never silently diverge. Pass `--push` to
skip the editor and run the website's preflight + commit + push in one step.

**Keep everything reconciled:**

```sh
zotcheck --list                  # orphaned notes + Zotero items with no note yet
citecheck draft.md               # every @citekey in a draft resolves in Library.json
```
