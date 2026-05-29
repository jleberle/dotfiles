local autocmd = vim.api.nvim_create_autocmd

autocmd("FileType", {
	pattern = { "markdown", "text" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		vim.opt_local.spell = true
		vim.opt_local.conceallevel = 2

		-- Better paragraph navigation
		vim.opt_local.formatoptions:remove("t")
	end,
})

-- Reload files changed outside nvim (e.g. pandoc output, git ops in another
-- tmux pane). Relies on tmux's `focus-events on`.
autocmd({ "FocusGained", "BufEnter", "TermClose", "TermLeave" }, {
	command = "checktime",
})
