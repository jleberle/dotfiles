local M = {}

-- paths.env is the single source of truth for workflow locations, but only fish
-- (shell/fish/conf.d/paths.fish) parses it; this module just reads the env vars
-- that file exported — real values whenever nvim is launched from a fish shell,
-- which is the normal case. Each getter carries a fallback for the rare launch
-- with no such environment (e.g. straight from a GUI launcher).

function M.zotero_library_bib()
	local value = vim.env.ZOTERO_LIBRARY_BIB
	if value and value ~= "" then
		return vim.fn.expand(value)
	end
	return vim.fn.expand("~/Documents/Library/Library.bib")
end

function M.zotero_library_json()
	local value = vim.env.ZOTERO_LIBRARY_JSON
	if value and value ~= "" then
		return vim.fn.expand(value)
	end
	return vim.fn.expand("~/Documents/Library/Library.json")
end

function M.website_repo()
	local value = vim.env.WEBSITE_REPO
	if value and value ~= "" then
		return vim.fn.expand(value)
	end
	return vim.fn.expand("~/git/website")
end

function M.website_drafts_dir()
	local value = vim.env.WEBSITE_DRAFTS_DIR
	if value and value ~= "" then
		return vim.fn.expand(value)
	end
	return vim.fn.expand("~/Notes/07 Blog/Drafts")
end

function M.research_archives_dir()
	local value = vim.env.RESEARCH_ARCHIVES_DIR
	if value and value ~= "" then
		return vim.fn.expand(value)
	end
	return vim.fn.expand("~/Notes/03 Research/Archives")
end

function M.reading_notes_dir()
	local value = vim.env.READING_NOTES_DIR
	if value and value ~= "" then
		return vim.fn.expand(value)
	end
	return vim.fn.expand("~/Notes/02 Notes/01 Reading Notes")
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
