return {
	{
		"neovim/nvim-lspconfig",

		config = function()
			local lspconfig = require("lspconfig")

			lspconfig.lua_ls.setup({})
			lspconfig.pyright.setup({})
			lspconfig.bashls.setup({})
		end,
	},

	{
		"stevearc/conform.nvim",

		config = function()
			require("conform").setup({
				formatters_by_ft = {
					lua = { "stylua" },
					python = { "black" },
					markdown = { "prettier" },
				},
			})

			vim.keymap.set("n", "<leader>f", function()
				require("conform").format({
					async = true,
				})
			end)
		end,
	},
}
