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
					-- Vale discovers .vale.ini upward from its *cwd*, not from
					-- the linted file (which arrives on stdin). Anchor cwd to
					-- the file's directory so project configs (website repo,
					-- valeinit scaffolds) apply regardless of nvim's cwd.
					lint.linters.vale.cwd = vim.fn.expand("%:p:h")
					lint.try_lint()
				end,
			})
		end,
	},
}
