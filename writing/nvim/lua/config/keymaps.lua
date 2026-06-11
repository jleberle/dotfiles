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
local pandoc_defaults = vim.fn.expand("~/.dotfiles/writing/pandoc/defaults.yaml")

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
