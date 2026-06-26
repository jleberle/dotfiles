local M = {}

-- paths.env is the single source of truth for these values, but only fish
-- (shell/fish/conf.d/paths.fish) ever parses it; this module just reads the
-- env vars that file already exported (real values whenever nvim is launched
-- from a fish shell — the normal case). The hardcoded fallbacks below mirror
-- the "paths.env not found" defaults in paths.fish, for the rare case nvim
-- runs without that environment.
local FALLBACKS = {
	ZOTERO_LIBRARY_JSON = "~/Documents/Library/Library.json",
	ZOTERO_LIBRARY_BIB = "~/Documents/Library/Library.bib",
	READING_NOTES_DIR = "~/Notes/02 Notes/01 Reading Notes",
	RESEARCH_NOTES_DIR = "~/Notes/02 Notes/02 Research Notes",
	RESEARCH_ARCHIVES_DIR = "~/Notes/03 Research/Archives",
	WEBSITE_REPO = "~/git/website",
}

function M.workflow_path(var, fallback)
	local value = vim.env[var]
	if value and value ~= "" then
		return vim.fn.expand(value)
	end
	return vim.fn.expand(fallback or FALLBACKS[var])
end

-- DOTFILES_DIR has a second fallback besides the table above: nvim's own
-- config location. `make nvim` symlinks ~/.config/nvim to <repo>/writing/nvim,
-- so resolving that symlink finds the repo even with no environment at all.
function M.dotfiles_dir()
	if vim.env.DOTFILES_DIR and vim.env.DOTFILES_DIR ~= "" then
		return vim.env.DOTFILES_DIR
	end
	local resolved_config = vim.fn.resolve(vim.fn.stdpath("config"))
	return vim.fs.dirname(vim.fs.dirname(resolved_config))
end

function M.zotero_library_bib()
	return M.workflow_path("ZOTERO_LIBRARY_BIB")
end

return M
