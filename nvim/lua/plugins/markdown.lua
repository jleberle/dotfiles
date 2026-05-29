return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {
			heading = {
				enabled = true,
			},

			code = {
				sign = false,
				width = "block",
			},

			bullet = {
				enabled = true,
			},

			-- No `latex` treesitter parser / pylatexenc installed; off by
			-- default avoids the one-time "missing latex" notice on startup.
			latex = {
				enabled = false,
			},
		},
	},
}
