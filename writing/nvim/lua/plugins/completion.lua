return {
	{
		"saghen/blink.cmp",
		-- Release tags ship a prebuilt fuzzy-matcher binary (no Rust toolchain
		-- needed); blink falls back to its Lua implementation if unavailable.
		version = "1.*",
		event = "InsertEnter",

		opts = {
			-- Enter confirms; C-n/C-p or arrows select. With preselect off,
			-- Enter inserts a newline unless an item was explicitly selected —
			-- matches the old nvim-cmp confirm({ select = false }) behavior.
			-- C-space opens the menu on demand since auto_show is off below.
			keymap = { preset = "enter", ["<C-space>"] = { "show" } },
			completion = {
				list = { selection = { preselect = false, auto_insert = true } },
				-- Don't pop up the menu on every keystroke while writing prose;
				-- only show it when explicitly requested (<C-space>).
				menu = { auto_show = false },
			},

			-- lsp/path/buffer match the old nvim-cmp setup (all built into
			-- blink). 'snippets' loads vscode-format files from the config
			-- dir's snippets/ (blink's default search path) — currently the
			-- pandoc-crossref snippets in snippets/markdown.json. LSP snippet
			-- completions still expand via vim.snippet natively.
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
				providers = {
					-- Only our own snippet files; skip the friendly-snippets
					-- collection (not installed).
					snippets = { opts = { friendly_snippets = false } },
				},
			},
		},
	},
}
