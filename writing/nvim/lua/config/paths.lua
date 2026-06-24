local M = {}

local function escape_pattern(text)
	return (text:gsub("(%W)", "%%%1"))
end

function M.dotfiles_dir()
	if vim.env.DOTFILES_DIR and vim.fn.isdirectory(vim.env.DOTFILES_DIR) == 1 then
		return vim.env.DOTFILES_DIR
	end

	local resolved_config = vim.fn.resolve(vim.fn.stdpath("config"))
	local inferred_root = vim.fs.dirname(vim.fs.dirname(resolved_config))
	if vim.fn.isdirectory(inferred_root .. "/writing/pandoc") == 1 then
		return inferred_root
	end

	return vim.fn.expand("~/.dotfiles")
end

local function tracked_workflow_path(var)
	local file = io.open(M.dotfiles_dir() .. "/shell/fish/conf.d/paths.fish", "r")
	if not file then
		return nil
	end

	local pattern = "^set %-q "
		.. escape_pattern(var)
		.. ";%s*or%s*set %-gx%s+"
		.. escape_pattern(var)
		.. "%s+(.+)$"

	for line in file:lines() do
		local value = line:match(pattern)
		if value then
			file:close()
			value = vim.trim(value):gsub('^"', ""):gsub('"$', "")
			value = value:gsub("%$HOME", vim.env.HOME or "")
			return vim.fn.expand(value)
		end
	end

	file:close()
	return nil
end

function M.workflow_path(var, fallback)
	if vim.env[var] and vim.env[var] ~= "" then
		return vim.fn.expand(vim.env[var])
	end

	return tracked_workflow_path(var) or (fallback and vim.fn.expand(fallback) or nil)
end

function M.zotero_library_bib()
	return M.workflow_path("ZOTERO_LIBRARY_BIB", "~/Documents/Library/Library.bib")
end

return M
