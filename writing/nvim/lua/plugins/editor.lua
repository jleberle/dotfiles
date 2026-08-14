return {
	{
		"stevearc/oil.nvim",
		cmd = "Oil",
		opts = {},
	},

	-- Pickers live in mini.pick (see plugins/writing.lua); the <leader>f* maps,
	-- including the citation picker, are in config/keymaps.lua.

	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			-- main branch API: no .configs.setup / ensure_installed / highlight.
			-- Parsers are installed imperatively (async; already-installed ones
			-- are skipped), and highlighting is started per-buffer on FileType.
			require("nvim-treesitter").install({
				"markdown",
				"markdown_inline",
				"lua",
				"python",
				"bash",
				"json",
				"yaml",
			})

			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "markdown", "lua", "python", "sh", "bash", "json", "yaml" },
				callback = function()
					-- pcall guards the first run, before parsers finish installing.
					pcall(vim.treesitter.start)
				end,
			})

			-- The buffer that triggered loading may have fired FileType already.
			pcall(vim.treesitter.start)
		end,
	},

	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = true,
	},

	{
		"tpope/vim-fugitive",
		cmd = "Git",
		keys = {
			{ "<leader>gs", "<cmd>Git<cr>", desc = "Git status" },
		},
	},
}
