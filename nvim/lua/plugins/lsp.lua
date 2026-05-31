return {
	{
		"neovim/nvim-lspconfig",
		ft = { "lua", "python", "sh", "bash", "go" },
		dependencies = { "hrsh7th/cmp-nvim-lsp" },
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			vim.lsp.config("lua_ls", { capabilities = capabilities })
			vim.lsp.config("pyright", { capabilities = capabilities })
			vim.lsp.config("bashls", { capabilities = capabilities })
			vim.lsp.config("gopls", { capabilities = capabilities })

			vim.lsp.enable({ "lua_ls", "pyright", "bashls", "gopls" })
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