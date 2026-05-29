return {
	{
		"stevearc/oil.nvim",
		opts = {},
	},

	{
		"nvim-telescope/telescope.nvim",
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
		config = true,
	},
}
