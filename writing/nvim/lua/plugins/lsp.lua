return {
	{
		"neovim/nvim-lspconfig",
		ft = { "lua", "python", "sh", "bash" },
		dependencies = { "saghen/blink.cmp" },
		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			vim.lsp.config("lua_ls", { capabilities = capabilities })
			vim.lsp.config("pyright", { capabilities = capabilities })
			vim.lsp.config("bashls", { capabilities = capabilities })
			vim.lsp.enable({ "lua_ls", "pyright", "bashls" })
		end,
	},
	{
		"stevearc/conform.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					lua = { "stylua" },
					python = { "black" },
					markdown = { "prettier" },
				},
			})
			vim.keymap.set("n", "<leader>cf", function()
				require("conform").format({
					async = true,
				})
			end, { desc = "Format buffer" })
		end,
	},
}