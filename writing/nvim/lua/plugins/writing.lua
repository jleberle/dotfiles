return {
	{
		"folke/zen-mode.nvim",
		cmd = "ZenMode",
		-- Inlined rather than given its own top-level spec: `opts` is
		-- load-bearing (it is what makes lazy call twilight.setup(), which
		-- populates twilight.config.options — require("twilight") does not
		-- self-initialize, and zen-mode's integration calls enable() straight
		-- into those options). `cmd` keeps :Twilight usable on its own.
		dependencies = {
			{ "folke/twilight.nvim", cmd = { "Twilight", "TwilightEnable" }, opts = {} },
		},
		opts = {
			window = {
				width = 90,
			},
			plugins = {
				twilight = { enabled = true },
			},
		},
	},

	-- mini.comment is deliberately absent: nvim ships `gc`/`gcc` built in.
	{
		"echasnovski/mini.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("mini.pairs").setup()
			require("mini.surround").setup()
		end,
	},
}
