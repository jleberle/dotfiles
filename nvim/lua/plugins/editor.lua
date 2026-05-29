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
		event = { "BufReadPost", "BufNewFile" },
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"markdown",
					"markdown_inline",
					"lua",
					"python",
					"bash",
					"json",
					"yaml",
				},
				highlight = {
					enable = true,
				},
			})
		end,
	},

	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = true,
	},
}
