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
		},
	},
}
