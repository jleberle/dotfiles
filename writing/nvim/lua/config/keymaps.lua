local map = vim.keymap.set
local paths = require("config.paths")

-- Diagnostics
map("n", "<leader>e", "<cmd>lua vim.diagnostic.open_float()<cr>", { desc = "Show diagnostic" })

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

-- Save/Quit
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Write file" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit window" })

-- Telescope
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Search in files" })
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Open buffers" })

-- Jump from the @citekey under the cursor to its item in Zotero (PDF and
-- notes are one keystroke away there). Better BibTeX registers the
-- zotero://select URL handler and resolves @citekey form; companion to the
-- <leader>fc picker, which inserts these keys.
map("n", "<leader>fo", function()
	-- Citekey chars per the pandoc spec (alphanumerics plus internal
	-- punctuation); the trailing strip drops sentence punctuation when the
	-- citation isn't bracket-terminated, e.g. "see @smith2020."
	local key = vim.fn.expand("<cWORD>"):match("@([%w_.:#$%%&+?<>~/%-]+)")
	if key then
		key = key:gsub("[.:#$%%&+?<>~/%-]+$", "")
	end
	if not key or key == "" then
		vim.notify("No @citekey under cursor", vim.log.levels.WARN)
		return
	end
	vim.ui.open("zotero://select/items/@" .. key)
end, { desc = "Open citation in Zotero" })

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

map("n", "<leader>ph", function()
	pandoc_export("html")
end, { desc = "Pandoc → HTML" })

map("n", "<leader>pp", function()
	pandoc_export("pdf")
end, { desc = "Pandoc → PDF" })

map("n", "<leader>pd", function()
	pandoc_export("docx")
end, { desc = "Pandoc → Word" })

-- Live preview in Marked 2 (re-renders on every save)
map("n", "<leader>pv", function()
	vim.cmd.update()
	vim.system({ "open", "-a", "Marked 2", vim.fn.expand("%:p") })
end, { desc = "Preview in Marked 2" })
