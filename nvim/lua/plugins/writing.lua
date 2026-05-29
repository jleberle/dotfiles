return {
	{
		"folke/zen-mode.nvim",
		opts = {
			window = {
				width = 90,
			},
		},
	},

	{
		"echasnovski/mini.nvim",
		config = function()
			require("mini.pairs").setup()
			require("mini.comment").setup()
			require("mini.surround").setup()
		end,
	},

	{
		"folke/twilight.nvim",
		opts = {},
	},
}
