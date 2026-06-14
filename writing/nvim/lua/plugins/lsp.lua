return {
	{
		"neovim/nvim-lspconfig",
		ft = { "lua", "python", "sh", "bash", "markdown" },
		dependencies = { "saghen/blink.cmp" },
		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			vim.lsp.config("lua_ls", { capabilities = capabilities })
			vim.lsp.config("pyright", { capabilities = capabilities })
			vim.lsp.config("bashls", { capabilities = capabilities })
			-- Cross-document Markdown navigation: go-to-definition on links and
			-- headings, link/reference completion, rename across files. Style is
			-- vale, grammar is harper_ls, spelling is vim's built-in spell.
			vim.lsp.config("marksman", { capabilities = capabilities })
			-- Grammar (not style — that's vale via nvim-lint, and not spelling
			-- — that's vim's built-in spell, so SpellCheck is off here).
			vim.lsp.config("harper_ls", {
				capabilities = capabilities,
				settings = {
					["harper-ls"] = {
						linters = { SpellCheck = false },
					},
				},
			})
			vim.lsp.enable({ "lua_ls", "pyright", "bashls", "harper_ls", "marksman" })
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