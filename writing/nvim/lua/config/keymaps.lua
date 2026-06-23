local map = vim.keymap.set

-- Diagnostics
map("n", "<leader>e", "<cmd>lua vim.diagnostic.open_float()<cr>", { desc = "Show diagnostic" })

-- Navigate by display line (respects word-wrap)
map({ "n", "x" }, "j", "gj")
map({ "n", "x" }, "k", "gk")

-- Save/Quit
map("n", "<leader>w", "<cmd>w<cr>")
map("n", "<leader>q", "<cmd>q<cr>")

-- Telescope
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>")
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>")
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>")

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
map("n", "<leader>z", "<cmd>ZenMode<cr>")

-- Oil file browser
map("n", "-", "<cmd>Oil<cr>")

-- Pandoc exports with citation + cross-reference processing. The pipeline
-- (crossref filter ordering, citeproc) lives in writing/pandoc/defaults.yaml,
-- shared with the fish mdexport function. Runs asynchronously (vim.system) so
-- the editor stays responsive during slow PDF/LaTeX builds; notifies on
-- completion. Runs from the document's own directory so relative paths in
-- metadata.yaml (bibliography, CSL) and relative image/links resolve.
local function dotfiles_dir()
	if vim.env.DOTFILES_DIR and vim.fn.isdirectory(vim.env.DOTFILES_DIR) == 1 then
		return vim.env.DOTFILES_DIR
	end

	local resolved_config = vim.fn.resolve(vim.fn.stdpath("config"))
	local inferred_root = vim.fs.dirname(vim.fs.dirname(resolved_config))
	if vim.fn.isdirectory(inferred_root .. "/writing/pandoc") == 1 then
		return inferred_root
	end

	return vim.fn.expand("~/.dotfiles")
end

local pandoc_defaults = dotfiles_dir() .. "/writing/pandoc/defaults.yaml"

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
			if result.code == 0 then
				vim.notify("Exported " .. output)
			else
				vim.notify("pandoc failed:\n" .. (result.stderr or "unknown error"), vim.log.levels.ERROR)
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
