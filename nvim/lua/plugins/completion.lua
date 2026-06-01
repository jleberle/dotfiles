return {
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-nvim-lsp",
		},

		config = function()
			local cmp = require("cmp")

			cmp.setup({
				-- Use Neovim's built-in snippet expander (0.10+) so accepting
				-- an LSP snippet completion doesn't error.
				snippet = {
					expand = function(args)
						vim.snippet.expand(args.body)
					end,
				},

				mapping = cmp.mapping.preset.insert({
					["<CR>"] = cmp.mapping.confirm({
						select = false,
					}),
				}),

				sources = {
					{ name = "nvim_lsp" },
					{ name = "buffer" },
					{ name = "path" },
				},
			})
		end,
	},
}
