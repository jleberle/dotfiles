return {
	{
		"gbprod/nord.nvim",
		priority = 1000,
		lazy = false,
		config = function()
			require("nord").setup({})
			vim.cmd.colorscheme("nord")
		end,
	},

	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		dependencies = { "echasnovski/mini.nvim" },
		config = function()
			require("mini.icons").setup()
			require("lualine").setup({
				options = {
					theme = "nord",
					globalstatus = true,
				},
			})
		end,
	},
}
