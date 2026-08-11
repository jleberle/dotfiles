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

	-- Press the leader key (`,`) and wait: a menu of what it can do appears,
	-- rendered from the `desc` field already set on every mapping. The shell got
	-- three answers to "what can this do?" — `make help`, bare `site`, and tab
	-- completion — while nvim, where the actual writing happens, had none: the
	-- export and citation mappings existed only in the source and the docs.
	-- Nothing to maintain here; adding a mapping with a desc lists it.
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "helix",
			-- Names for the prefixes, so `,p` and `,f` are not bare letters.
			spec = {
				{ "<leader>p", group = "pandoc / preview" },
				{ "<leader>f", group = "find / citations" },
				{ "<leader>c", group = "code" },
			},
		},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = true })
				end,
				desc = "All keymaps",
			},
		},
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
