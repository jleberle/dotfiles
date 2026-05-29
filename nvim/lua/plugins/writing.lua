return {
	{
		"folke/zen-mode.nvim",
		cmd = "ZenMode",
		opts = {
			window = {
				width = 90,
			},
		},
	},

	{
		"echasnovski/mini.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("mini.pairs").setup()
			require("mini.comment").setup()
			require("mini.surround").setup()
		end,
	},

	{
		"folke/twilight.nvim",
		cmd = { "Twilight", "TwilightEnable" },
		opts = {},
	},
}
