return {
	{
		"stevearc/oil.nvim",
		cmd = "Oil",
		opts = {},
	},

	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("telescope").setup({
				defaults = {
					layout_strategy = "horizontal",
				},
			})
		end,
	},

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
}
