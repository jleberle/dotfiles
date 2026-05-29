return {
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPost", "BufWritePost" },

		config = function()
			local lint = require("lint")

			lint.linters_by_ft = {
				markdown = { "vale" },
			}

			-- Lint on read/save only. InsertLeave/BufEnter fire constantly
			-- while writing prose and would spawn a vale process per pause.
			vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},
}
