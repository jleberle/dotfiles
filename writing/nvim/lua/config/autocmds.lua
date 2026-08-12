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

-- `<leader>fa` (archival OCR search) populates the quickfix list with
-- file:page hits from `arch grep`, and quickfix's default <CR> would load a
-- PDF's raw bytes into a buffer. Open it in Preview instead and drop the
-- buffer nvim already created for it, so :cnext/:cprev over the list still
-- works normally.
autocmd("BufReadCmd", {
	pattern = "*.pdf",
	callback = function(args)
		vim.system({ "open", args.file })
		vim.schedule(function()
			vim.cmd.bwipeout({ bang = true })
		end)
	end,
})
