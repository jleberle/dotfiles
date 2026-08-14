local M = {}

-- paths.env is the single source of truth for workflow locations, but only fish
-- (shell/fish/conf.d/paths.fish) parses it; this module just reads the env vars
-- that file exported — real values whenever nvim is launched from a fish shell,
-- which is the normal case. Each getter carries a fallback for the rare launch
-- with no such environment (e.g. straight from a GUI launcher).
local defaults = {
	zotero_library_bib = { "ZOTERO_LIBRARY_BIB", "~/Documents/Library/Library.bib" },
	zotero_library_json = { "ZOTERO_LIBRARY_JSON", "~/Documents/Library/Library.json" },
	website_repo = { "WEBSITE_REPO", "~/git/website" },
	website_drafts_dir = { "WEBSITE_DRAFTS_DIR", "~/Notes/07 Blog/Drafts" },
	research_archives_dir = { "RESEARCH_ARCHIVES_DIR", "~/Notes/03 Research/Archives" },
	reading_notes_dir = { "READING_NOTES_DIR", "~/Notes/02 Notes/01 Reading Notes" },
}

for name, spec in pairs(defaults) do
	local var, fallback = spec[1], spec[2]
	M[name] = function()
		local value = vim.env[var]
		return vim.fn.expand(value ~= nil and value ~= "" and value or fallback)
	end
end

-- DOTFILES_DIR falls back to nvim's own config location: `make nvim` symlinks
-- ~/.config/nvim to <repo>/writing/nvim, so resolving that symlink finds the
-- repo even with no environment at all.
function M.dotfiles_dir()
	if vim.env.DOTFILES_DIR and vim.env.DOTFILES_DIR ~= "" then
		return vim.env.DOTFILES_DIR
	end
	local resolved_config = vim.fn.resolve(vim.fn.stdpath("config"))
	return vim.fs.dirname(vim.fs.dirname(resolved_config))
end

return M
