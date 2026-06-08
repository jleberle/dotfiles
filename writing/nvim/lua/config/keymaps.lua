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

-- Pandoc exports with citation + cross-reference processing.
-- Runs from the document's own directory so relative paths in metadata.yaml
-- (bibliography, CSL) and relative image/links resolve correctly. pandoc-crossref
-- must precede --citeproc, since pandoc applies filters left-to-right.
local function pandoc_export(ext)
	local dir = vim.fn.expand("%:p:h")
	local file = vim.fn.shellescape(vim.fn.expand("%:t"))
	local output = vim.fn.shellescape(vim.fn.expand("%:t:r") .. "." .. ext)

	local cmd = "pandoc --filter pandoc-crossref --citeproc " .. file .. " -o " .. output

	-- Pick up a sibling metadata.yaml (bibliography, CSL, etc.) if present.
	if vim.fn.filereadable(dir .. "/metadata.yaml") == 1 then
		cmd = cmd .. " --metadata-file=metadata.yaml"
	end

	vim.cmd("!cd " .. vim.fn.shellescape(dir) .. " && " .. cmd)
end

map("n", "<leader>ph", function()
	pandoc_export("html")
end, { desc = "Pandoc → HTML" })

map("n", "<leader>pp", function()
	pandoc_export("pdf")
end, { desc = "Pandoc → PDF" })
