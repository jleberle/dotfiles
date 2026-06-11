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
			keymap = { preset = "enter" },
			completion = {
				list = { selection = { preselect = false, auto_insert = true } },
			},

			-- Same sources as the old nvim-cmp setup (all built into blink).
			-- The blink default also includes 'snippets' (vscode-style snippet
			-- files), which this setup doesn't use; LSP snippet completions
			-- still expand via vim.snippet natively.
			sources = {
				default = { "lsp", "path", "buffer" },
			},
		},
	},
}
