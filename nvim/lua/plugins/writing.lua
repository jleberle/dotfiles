return {
	{
		"folke/zen-mode.nvim",
		cmd = "ZenMode",
		dependencies = { "folke/twilight.nvim" },
		opts = {
			window = {
				width = 90,
			},
			plugins = {
				twilight = { enabled = true },
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
