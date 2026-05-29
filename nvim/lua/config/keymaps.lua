local map = vim.keymap.set

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

-- Pandoc exports
map("n", "<leader>ph", function()
	local file = vim.fn.expand("%")
	local output = vim.fn.expand("%:r") .. ".html"
	vim.cmd("!" .. "pandoc " .. file .. " -o " .. output)
end)

map("n", "<leader>pp", function()
	local file = vim.fn.expand("%")
	local output = vim.fn.expand("%:r") .. ".pdf"
	vim.cmd("!" .. "pandoc " .. file .. " -o " .. output)
end)
