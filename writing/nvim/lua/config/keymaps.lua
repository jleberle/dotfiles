local map = vim.keymap.set
local paths = require("config.paths")

-- Several mappings below call fish *functions* (site, arch, readnote,
-- mdarchive) that live in shell/fish/functions/ rather than on $PATH, so
-- vim.system can't exec them directly — routed through `fish -c`, which
-- autoloads functions the same as an interactive shell. Each argument is
-- shell-escaped into that one script string (fish's single-quote escaping
-- matches POSIX closely enough for shellescape's output to round-trip).
local function fish_cmd(args)
	local quoted = {}
	for _, a in ipairs(args) do
		table.insert(quoted, vim.fn.shellescape(a))
	end
	return { "fish", "-c", table.concat(quoted, " ") }
end

local function strip_ansi(s)
	return (s:gsub("\27%[[0-9;]*m", ""))
end

-- Citekey chars per the pandoc spec (alphanumerics plus internal
-- punctuation); the trailing strip drops sentence punctuation when the
-- citation isn't bracket-terminated, e.g. "see @smith2020."
local function citekey_under_cursor()
	local key = vim.fn.expand("<cWORD>"):match("@([%w_.:#$%%&+?<>~/%-]+)")
	if key then
		key = key:gsub("[.:#$%%&+?<>~/%-]+$", "")
	end
	return key
end

-- Run `cmd` asynchronously and report its combined output through vim.notify.
-- `fail_level` is the level for a non-zero exit: WARN for checks that routinely
-- report findings (a dead link is news, not a malfunction), ERROR for
-- operations that were supposed to succeed.
local function run_notify(cmd, title, fail_level)
	vim.system(cmd, { text = true }, function(result)
		vim.schedule(function()
			local output = strip_ansi(vim.trim((result.stdout or "") .. "\n" .. (result.stderr or "")))
			local level = result.code == 0 and vim.log.levels.INFO or fail_level
			vim.notify(output, level, { title = title })
		end)
	end)
end

-- Diagnostics
map("n", "<leader>e", "<cmd>lua vim.diagnostic.open_float()<cr>", { desc = "Show diagnostic" })

-- Nvim 0.11+ auto-binds grn/gra/grr/gri/grt/gO and K (hover) on LSP attach,
-- but not goto-definition — the one marksman mapping that matters most here,
-- since it's how a [[wikilink]] or markdown link under the cursor jumps to
-- the note it points to (title- or filename-matched per .marksman.toml).
map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition (follow link)" })

-- Navigate by display line (respects word-wrap) — but only without a count.
-- Bare `gj` moves one wrapped row, which is what prose wants; `10j` with the
-- unconditional remap became `10gj`, ten *display* rows, which in a wrapped
-- paragraph is nowhere near ten lines down. The count form also has to keep
-- working for code buffers (lua, sh, python via LSP), where wrap is off and the
-- remap is pure loss.
map({ "n", "x" }, "j", function()
	return vim.v.count == 0 and "gj" or "j"
end, { expr = true, desc = "Down (by display line)" })
map({ "n", "x" }, "k", function()
	return vim.v.count == 0 and "gk" or "k"
end, { expr = true, desc = "Up (by display line)" })

-- Clipboard (clipboard=unnamedplus in options.lua aliases the unnamed
-- register to the system clipboard, so plain y/p already are "copy/paste".
-- Two gaps that leaves: deletes clobber the clipboard too, and visual-mode
-- paste overwrites the paste buffer with the text it just replaced.
map({ "n", "x" }, "<leader>d", '"_d', { desc = "Delete without clobbering clipboard" })
map("x", "p", '"_dP', { desc = "Paste over selection (keep register)" })

-- Save/Quit
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Write file" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit window" })

-- Pickers (mini.pick)
map("n", "<leader>ff", "<cmd>Pick files<cr>", { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Pick grep_live<cr>", { desc = "Search in files" })
map("n", "<leader>fb", "<cmd>Pick buffers<cr>", { desc = "Open buffers" })
map("n", "<leader>fc", "<cmd>Pick citations<cr>", { desc = "Insert citation" })

-- Jump from the @citekey under the cursor to its item in Zotero (PDF and
-- notes are one keystroke away there). Better BibTeX registers the
-- zotero://select URL handler and resolves @citekey form; companion to the
-- <leader>fc picker, which inserts these keys.
map("n", "<leader>fo", function()
	local key = citekey_under_cursor()
	if not key or key == "" then
		vim.notify("No @citekey under cursor", vim.log.levels.WARN)
		return
	end
	vim.ui.open("zotero://select/items/@" .. key)
end, { desc = "Open citation in Zotero" })

-- Open the reading note for the @citekey under the cursor, or create it
-- (`readnote`) if it doesn't exist yet — closes the same zotcheck loop the
-- fish function does, one keystroke from the citation instead of the shell.
-- readnote's own `nvim $file` only fires when run interactively, which
-- `fish -c` isn't, so this opens the result itself rather than racing a
-- second nvim.
map("n", "<leader>fr", function()
	local key = citekey_under_cursor()
	if not key or key == "" then
		vim.notify("No @citekey under cursor", vim.log.levels.WARN)
		return
	end

	local file = paths.reading_notes_dir() .. "/" .. key .. ".md"
	if vim.fn.filereadable(file) == 1 then
		vim.cmd.edit(file)
		return
	end

	vim.notify("Creating reading note for @" .. key .. " …")
	vim.system(fish_cmd({ "readnote", key }), { text = true }, function(result)
		vim.schedule(function()
			if result.code ~= 0 then
				local output = strip_ansi(vim.trim((result.stdout or "") .. "\n" .. (result.stderr or "")))
				vim.notify("readnote failed:\n" .. output, vim.log.levels.ERROR)
				return
			end
			vim.cmd.edit(file)
		end)
	end)
end, { desc = "Open/create reading note for citekey under cursor" })

-- Full-text search the OCR'd archival scans (`arch grep` -> ripgrep-all),
-- into the quickfix list as file:page hits. <CR> on a hit would otherwise
-- load a PDF's raw bytes as a buffer; the BufReadCmd autocmd in
-- autocmds.lua intercepts *.pdf and opens it in Preview instead.
map("n", "<leader>fa", function()
	local query = vim.fn.input("Search archives: ")
	if vim.trim(query) == "" then
		return
	end

	vim.notify('Searching archives for "' .. query .. '" …')
	vim.system(fish_cmd({ "arch", "grep", query }), { text = true }, function(result)
		vim.schedule(function()
			local items = {}
			for line in (result.stdout or ""):gmatch("[^\n]+") do
				local file, page, text = line:match("^(.-):(%d+):(.*)$")
				if file then
					table.insert(items, { filename = file, lnum = tonumber(page), text = text })
				end
			end

			if #items == 0 then
				local err = strip_ansi(vim.trim(result.stderr or ""))
				vim.notify('No matches for "' .. query .. '"' .. (err ~= "" and ("\n" .. err) or ""), vim.log.levels.WARN)
				return
			end

			vim.fn.setqflist(items, "r")
			vim.cmd.copen()
			vim.notify(#items .. ' match(es) for "' .. query .. '" — <CR> opens the PDF in Preview')
		end)
	end)
end, { desc = "Search archival OCR text (arch grep)" })

-- Zen mode
map("n", "<leader>z", "<cmd>ZenMode<cr>", { desc = "Zen mode" })

-- Oil file browser
map("n", "-", "<cmd>Oil<cr>", { desc = "Browse files (Oil)" })

-- Pandoc exports with citation + cross-reference processing. The pipeline
-- (crossref filter ordering, citeproc) lives in writing/pandoc/defaults.yaml,
-- shared with the fish mdexport function. Runs asynchronously (vim.system) so
-- the editor stays responsive during slow PDF/LaTeX builds; notifies on
-- completion. Runs from the document's own directory so relative paths in
-- metadata.yaml (bibliography, CSL) and relative image/links resolve.
local pandoc_defaults = paths.dotfiles_dir() .. "/writing/pandoc/defaults.yaml"

local function pandoc_export(ext)
	vim.cmd.update() -- write the buffer first (only if modified)

	local dir = vim.fn.expand("%:p:h")
	local file = vim.fn.expand("%:t")
	local output = vim.fn.expand("%:t:r") .. "." .. ext

	local cmd = { "pandoc", "-d", pandoc_defaults, file, "-o", output }

	-- Pick up a sibling metadata.yaml (bibliography, CSL, etc.) if present.
	if vim.fn.filereadable(dir .. "/metadata.yaml") == 1 then
		table.insert(cmd, "--metadata-file=metadata.yaml")
	end

	vim.notify("Exporting " .. output .. " …")
	vim.system(cmd, { cwd = dir }, function(result)
		vim.schedule(function()
			if result.code ~= 0 then
				vim.notify("pandoc failed:\n" .. (result.stderr or "unknown error"), vim.log.levels.ERROR)
				return
			end

			-- Pandoc exits 0 for an unresolvable citation: it warns on stderr and
			-- writes "smith2020?" into the document. Reporting only the exit code
			-- meant a plain "Exported chapter.docx" for a file whose citations are
			-- broken — and that file is the one that goes to an editor. Warnings
			-- are surfaced on success too, at WARN level so the clean case still
			-- reads as clean. `citecheck` catches this earlier; nothing runs it
			-- automatically.
			local warnings = vim.trim(result.stderr or "")
			if warnings ~= "" then
				vim.notify("Exported " .. output .. ", with warnings:\n" .. warnings, vim.log.levels.WARN)
			else
				vim.notify("Exported " .. output)
			end
		end)
	end)
end

-- Validate every @citekey in the buffer against the Zotero library before
-- export, so a typo'd or deleted citekey surfaces here instead of as
-- "smith2020?" in an exported PDF (see the pandoc_export warning handling
-- below, which only catches this at export time).
map("n", "<leader>pc", function()
	vim.cmd.update()

	local file = vim.fn.expand("%:p")
	local cmd = { paths.dotfiles_dir() .. "/bin/citecheck.py", paths.zotero_library_json(), file }

	vim.system(cmd, { text = true }, function(result)
		vim.schedule(function()
			local output = vim.trim((result.stdout or "") .. (result.stderr or ""))
			if result.code ~= 0 then
				vim.notify(output ~= "" and output or "citecheck failed", vim.log.levels.ERROR)
			else
				vim.notify(output)
			end
		end)
	end)
end, { desc = "Check citations against Zotero library" })

-- Check every link in the buffer (lychee) before export/publish — same
-- pre-flight spirit as <leader>pc, but for URLs instead of citekeys. lychee
-- is a real binary on $PATH, so this runs directly, no fish -c needed.
map("n", "<leader>pl", function()
	vim.cmd.update()
	vim.notify("Checking links …")
	run_notify({ "lychee", "--no-progress", vim.fn.expand("%:p") }, "linkcheck", vim.log.levels.WARN)
end, { desc = "Check links in buffer (lychee)" })

-- Snapshot every URL cited in the buffer to the Wayback Machine (`mdarchive`)
-- — worth running right before publishing a piece that cites web sources, so
-- a citation still resolves after the original page moves or disappears.
-- Confirms first: archiving is slow (~30s+ per URL on a link-heavy piece).
map("n", "<leader>pa", function()
	vim.cmd.update()
	local file = vim.fn.expand("%:p")

	if vim.fn.confirm("Archive every cited URL to the Wayback Machine? (slow: ~30s+/URL)", "&Yes\n&No", 2) ~= 1 then
		return
	end

	vim.notify("Archiving cited URLs …")
	run_notify(fish_cmd({ "mdarchive", file }), "mdarchive", vim.log.levels.WARN)
end, { desc = "Archive cited URLs to the Wayback Machine" })

-- Publish the current buffer as a finished draft (site publish --cite),
-- moving it out of the Obsidian vault and into content/. Confirms first: this
-- deletes the draft from the vault, and there's no undo once the file's gone.
map("n", "<leader>bp", function()
	vim.cmd.update()

	local path = vim.fn.expand("%:p")
	local drafts_root = paths.website_drafts_dir()
	if vim.fn.stridx(path, drafts_root) ~= 0 then
		vim.notify("Not a website draft (expected under " .. drafts_root .. ")", vim.log.levels.WARN)
		return
	end

	if vim.fn.confirm("Publish " .. vim.fn.fnamemodify(path, ":t") .. " into content/?", "&Yes\n&No", 2) ~= 1 then
		return
	end

	local old_buf = vim.api.nvim_get_current_buf()
	vim.notify("Publishing " .. vim.fn.fnamemodify(path, ":t") .. " …")

	vim.system(fish_cmd({ "site", "publish", "--cite", path }), { text = true }, function(result)
		vim.schedule(function()
			local combined = vim.trim((result.stdout or "") .. "\n" .. (result.stderr or ""))
			if result.code ~= 0 then
				vim.notify("Publish failed:\n" .. strip_ansi(combined), vim.log.levels.ERROR)
				return
			end

			vim.notify(strip_ansi(combined))

			-- publish-draft.sh prints "  -> content/…/index.md" (repo-relative)
			-- on success; open that in place of the now-deleted draft buffer.
			local target = (result.stdout or ""):match("%-> (.-)\n")
			if target then
				vim.cmd.edit(paths.website_repo() .. "/" .. vim.trim(target))
				vim.api.nvim_buf_delete(old_buf, { force = true })
			end
		end)
	end)
end, { desc = "Publish current draft to content/" })

-- Preflight gate (site check / scripts/preflight.sh): blocking failures +
-- advisories. Async since a full run builds the site with Hugo.
map("n", "<leader>bc", function()
	vim.notify("Running site check …")
	run_notify(fish_cmd({ "site", "check" }), "site check", vim.log.levels.ERROR)
end, { desc = "Run site preflight checks" })

-- Ship (site ship / scripts/ship.sh): stages EVERY pending change in the
-- website repo (git add -A), commits, runs preflight, and pushes. Prompts for
-- the commit message here (ship.sh's own prompt would otherwise read from a
-- closed stdin under vim.system and silently abort as "Aborted"), and passes
-- --yes since the file-list confirmation has the same problem. Confirms
-- intent before running at all — this is the one that reaches the remote.
map("n", "<leader>bs", function()
	vim.cmd.update()

	local msg = vim.fn.input("Ship commit message: ")
	if vim.trim(msg) == "" then
		vim.notify("Ship cancelled: empty commit message", vim.log.levels.WARN)
		return
	end

	if vim.fn.confirm('Commit and push website repo as "' .. msg .. '"?', "&Yes\n&No", 2) ~= 1 then
		return
	end

	vim.notify("Shipping …")
	run_notify(fish_cmd({ "site", "ship", "--yes", msg }), "site ship", vim.log.levels.ERROR)
end, { desc = "Commit and push the website repo" })

for _, e in ipairs({
	{ "ph", "html", "Pandoc → HTML" },
	{ "pp", "pdf", "Pandoc → PDF" },
	{ "pd", "docx", "Pandoc → Word" },
}) do
	map("n", "<leader>" .. e[1], function()
		pandoc_export(e[2])
	end, { desc = e[3] })
end

-- Live preview in Marked 2 (re-renders on every save)
map("n", "<leader>pv", function()
	vim.cmd.update()
	vim.system({ "open", "-a", "Marked 2", vim.fn.expand("%:p") })
end, { desc = "Preview in Marked 2" })
