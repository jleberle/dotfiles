# Emacs (test config, mirrors Neovim)

This is a second editor config, built to mirror [`writing/nvim`](../writing/nvim)
package-for-package and mapping-for-mapping wherever Emacs has a real
equivalent. It exists as a test of Emacs for the same writing workflow — it
is **not** wired into `make install`, `make doctor`, or CI, and it is
deliberately not listed in the README's "where to go next" table. Nothing
elsewhere in the repo depends on it. Run `make emacs` to try it; everything
below explains what got ported, how, and where the mapping breaks down.

## Setup

```sh
make emacs   # symlinks writing/emacs -> ~/.config/emacs
```

The Brewfile adds two packages for this: `emacs` itself, and `aspell` —
flyspell (the `spelllang`/spellfile equivalent) needs an external spell-check
binary, unlike vim's built-in `spell`, which needs none.

First launch bootstraps [`straight.el`](https://github.com/radian-software/straight.el)
(a git-based package manager, playing the role `lazy.nvim` plays in the nvim
config) and then every package below. That first run needs network access —
same requirement, and the same friendly error on failure, as nvim's
`lazy.nvim` bootstrap.

`straight-base-dir` is pinned to `$XDG_DATA_HOME/emacs/` (`init.el`), not the
default `user-emacs-directory`. Since `make emacs` symlinks
`~/.config/emacs` straight at this repo, the default would clone every
package's git repo *inside* the tracked repo; nvim avoids the equivalent
problem because `lazy.nvim` already installs to `stdpath("data")`, outside
`stdpath("config")`. This repins Emacs to the same separation: config in the
repo, downloaded packages outside it. [`no-littering`](https://github.com/emacsmirror/no-littering)
does the same job for the incidental files Emacs and its packages write
(`custom.el`, backups, auto-save, transient history, …).

Unlike nvim's committed `lazy-lock.json`, there is no pinned package-version
lockfile committed here yet. `M-x straight-freeze-versions` writes one to
`$XDG_DATA_HOME/emacs/straight/versions/default.el` — outside the repo, by
the same design above — so reproducing nvim's "commit the lockfile" model
would mean deliberately copying it back in. Left undone for now since this
is a single-machine test, not a rollout.

## Layout

```
writing/emacs/
├── early-init.el             # pre-package-load setup (skip package.el, defer GUI chrome)
├── init.el                   # straight.el bootstrap + loads the modules below
├── lisp/
│   ├── config/
│   │   ├── options.el        # editor options
│   │   ├── keymaps.el        # global key mappings
│   │   ├── autocmds.el       # filetype + focus hooks
│   │   └── paths.el          # workflow locations (paths.env), same contract as nvim's paths.lua
│   └── packages/
│       ├── ui.el              # nord-theme, doom-modeline, which-key
│       ├── editor.el          # dired, vertico/orderless/marginalia/consult, treesit-auto, diff-hl
│       ├── completion.el      # corfu, cape, yasnippet
│       ├── lsp.el             # eglot + apheleia (formatting)
│       ├── linting.el         # flycheck (vale)
│       ├── markdown-cfg.el    # markdown-mode + valign
│       ├── writing.el         # olivetti, electric-pair, embrace
│       └── citations.el       # citar
├── snippets/markdown-mode/    # yasnippet ports of snippets/markdown.json
└── ispell/en.pws              # personal dictionary (equivalent of spell/en.utf-8.add)
```

## Key mappings

Emacs isn't modal — text you type is always inserted unless a command
explicitly took over the keyboard — so nvim's bare `,` leader has no safe
Emacs equivalent; binding a literal comma globally would swallow every comma
typed in prose. `C-c` is the prefix Emacs itself reserves for user bindings,
so it plays leader's role here. Everything after it mirrors the nvim table
letter-for-letter, so muscle memory carries over even though the trigger key
doesn't:

| nvim (`writing/nvim`) | Emacs (`writing/emacs`) | Action                                    |
|------------------------|--------------------------|--------------------------------------------|
| `<leader>w`            | `C-c w`                  | Save the buffer                             |
| `<leader>q`            | `C-c q`                  | Quit the window                             |
| `<leader>ff`           | `C-c f f`                | Find file                                   |
| `<leader>fg`           | `C-c f g`                | Live grep (`consult-ripgrep`)               |
| `<leader>fb`           | `C-c f b`                | Switch buffer (`consult-buffer`)            |
| `<leader>fc`           | `C-c f c`                | Insert citation (`citar-insert-citation`)   |
| `<leader>fo`           | `C-c f o`                | Open the `@citekey` near point in Zotero    |
| `<leader>z`            | `C-c z`                  | Toggle distraction-free mode (`olivetti`)   |
| `<leader>cf`           | `C-c c f`                | Format the buffer (`apheleia`)              |
| `<leader>ph`           | `C-c p h`                | Pandoc export → HTML                        |
| `<leader>pp`           | `C-c p p`                | Pandoc export → PDF                         |
| `<leader>pd`           | `C-c p d`                | Pandoc export → docx                        |
| `<leader>pv`           | `C-c p v`                | Preview in Marked 2                         |
| `<C-space>`            | `C-c TAB`                | Open the completion menu on demand          |
| `-` (Oil)              | `C-x C-j` (built-in)     | Browse the current file's directory         |
| `<leader>e`            | *(none needed)*          | Flycheck already shows diagnostics inline; `C-c ! l` (flycheck's own prefix) lists them |
| *(none)*               | `C-c g`                  | Open Magit (`magit-status`) — no nvim mapping to mirror, see below |

`sa`/`sd`/`sr` (mini.surround) map to `C-c s a`/`C-c s d`/`C-c s c`
(`embrace`) — under `C-c` for the same modal-vs-not reason as the leader
key, rather than nvim's motion-triggered `sa<motion>` form.

`gcc`/`gc` (mini.comment) need no mapping: Emacs's own `M-;` (`comment-dwim`)
already does this and predates the port.

## Package mapping

Mirrors [`writing/nvim/lua/plugins/*`](../writing/nvim/lua/plugins) one file
at a time. Where nvim's plugin choice has no real Emacs equivalent, the
table says so rather than forcing a fragile substitute.

| Layer | nvim | Emacs | Notes |
|---|---|---|---|
| Plugin manager | `lazy.nvim` | `straight.el` + `use-package` | Both git-based, both async-capable |
| Theme | `nord.nvim` | `nord-theme` | Same palette |
| Statusline | `lualine` (+ word count) | `doom-modeline` (+ word count) | Word count added via `global-mode-string` |
| Leader menu | `which-key.nvim` | `which-key` | Same package family; reads the same idea of a leader (`C-c` here) |
| File browser | `oil.nvim` | `dired` (built-in) | Oil's "directory as an editable buffer" *is* dired's native model |
| Fuzzy finder | `telescope.nvim` | `vertico` + `orderless` + `marginalia` + `consult` | Minibuffer completion, not a separate popup UI — the idiomatic Emacs shape for this |
| Citation picker | `telescope-bibtex` | `citar` | Both read the Better BibTeX `.bib` export directly |
| Syntax | `nvim-treesitter` (main) | Built-in `treesit` + `treesit-auto` | Both install/remap grammars on demand |
| Git gutter | `gitsigns.nvim` | `diff-hl` | Fringe markers |
| Completion | `blink.cmp` | `corfu` + `cape` | Menu-on-demand only, not on every keystroke, in both |
| Snippets | blink's `snippets` source, `snippets/markdown.json` | `yasnippet`, `snippets/markdown-mode/` | Ported by hand (vscode JSON → yasnippet format); same directory convention |
| LSP client | `nvim-lspconfig` | `eglot` (built-in) | Both are thin config layers, not full frameworks |
| Formatting | `conform.nvim` (stylua/black/prettier) | `apheleia` (same three formatters) | Manual trigger only in both, no format-on-save |
| Prose linting | `nvim-lint` (vale) | `flycheck` custom `vale` checker | Same `vale` binary, same cwd-discovery caveat for `.vale.ini` |
| Markdown rendering | `render-markdown.nvim` | `markdown-mode` (+ `valign` for tables) | See gaps below |
| Distraction-free | `zen-mode.nvim` + `twilight.nvim` | `olivetti` | Centers text; no twilight-style dimming of inactive code (see gaps) |
| Auto-pairs | `mini.pairs` | `electric-pair-mode` (built-in) | |
| Comment toggle | `mini.comment` | `comment-dwim` (built-in, `M-;`) | |
| Surround | `mini.surround` | `embrace` | |
| Undo persistence | `undofile` (built-in vim option) | `undo-fu-session` | |
| Autoreload | manual `FocusGained`/`checktime` autocmd + tmux `focus-events on` | `global-auto-revert-mode` (built-in) | Emacs's built-in is strictly simpler here — no tmux dependency |
| Git porcelain | *(none — gitsigns is gutter-only)* | `magit` | Not a port: `writing/nvim` has no full git UI to mirror. Added because Magit has no real vim/nvim equivalent — staged-hunk-level interactive rebase, blame, and log navigation as a first-class buffer. `C-c g` (`magit-status`) |

### Known gaps

A few nvim pieces don't have a faithful Emacs twin, so the port is honest
about the difference rather than papering over it:

- **Grammar checking (`harper_ls`) alongside navigation (`marksman`).** nvim
  runs both LSP servers on a markdown buffer at once (`vim.lsp.enable`).
  `eglot` manages one server per buffer, so `lsp.el` wires `marksman`
  (cross-document navigation); run `harper_ls` by hand with `M-x eglot` in a
  buffer where grammar-checking matters more than link navigation.
- **`<leader>fo` (open citation in Zotero)** resolves the exact `@citekey`
  WORD under the cursor in nvim. The Emacs port (`C-c f o`) takes the
  nearest `@key` on the current line instead — simpler, and covers the
  common one-citation-per-line case, but isn't identical for a line with
  more than one citation.
- **`twilight.nvim`'s dimming** (fading everything but the paragraph in
  view) has no port; `olivetti` only covers zen-mode's centering half.
- **Vale's severity level** isn't visible to the Emacs checker: `vale
  --output=line` (what `flycheck-define-checker` parses) doesn't carry
  it, so every hit surfaces as a `warning`. `--output=JSON` has severity if
  this needs upgrading later.
- **Window-split placement** (`splitbelow`/`splitright`) has no single
  Emacs variable pair that reproduces it; `options.el` leans on Emacs's own
  `split-window-sensibly` heuristic instead, which is close but not the same
  rule.

## Updating

Not part of `make update` (see the note that target prints). Inside Emacs:

```
M-x straight-pull-all      ; update every package to its latest commit
M-x straight-freeze-versions   ; optional — write a lockfile, see Setup above
```
