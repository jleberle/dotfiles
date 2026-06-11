return {
	{
		"gbprod/nord.nvim",
		priority = 1000,
		lazy = false,
		config = function()
			require("nord").setup({})
			vim.cmd.colorscheme("nord")
		end,
	},

	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		dependencies = { "echasnovski/mini.nvim" },
		config = function()
			require("mini.icons").setup()

			-- Word count for prose buffers; counts the selection in visual mode.
			local function wordcount()
				if vim.bo.filetype ~= "markdown" and vim.bo.filetype ~= "text" then
					return ""
				end
				local wc = vim.fn.wordcount()
				return (wc.visual_words or wc.words) .. " words"
			end

			require("lualine").setup({
				options = {
					theme = "nord",
					globalstatus = true,
				},
				-- Overrides only lualine_x; other sections keep their defaults.
				sections = {
					lualine_x = { wordcount, "encoding", "fileformat", "filetype" },
				},
			})
		end,
	},
}
