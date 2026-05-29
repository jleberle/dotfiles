return {
	{
		"neovim/nvim-lspconfig",
		ft = { "lua", "python", "sh", "bash" },
		dependencies = { "hrsh7th/cmp-nvim-lsp" },

		config = function()
			local lspconfig = require("lspconfig")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			lspconfig.lua_ls.setup({ capabilities = capabilities })
			lspconfig.pyright.setup({ capabilities = capabilities })
			lspconfig.bashls.setup({ capabilities = capabilities })
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

			-- <leader>cf, not <leader>f, to avoid colliding with the
			-- <leader>ff/fg/fb Telescope prefix (300ms timeoutlen delay).
			vim.keymap.set("n", "<leader>cf", function()
				require("conform").format({
					async = true,
				})
			end, { desc = "Format buffer" })
		end,
	},
}
