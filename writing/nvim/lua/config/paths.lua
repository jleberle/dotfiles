local M = {}

local function inferred_root()
	if vim.env.DOTFILES_DIR and vim.fn.isdirectory(vim.env.DOTFILES_DIR) == 1 then
		return vim.env.DOTFILES_DIR
	end

	local resolved_config = vim.fn.resolve(vim.fn.stdpath("config"))
	local candidate = vim.fs.dirname(vim.fs.dirname(resolved_config))
	if vim.fn.filereadable(candidate .. "/paths.env") == 1 then
		return candidate
	end
	if vim.fn.isdirectory(candidate .. "/writing/pandoc") == 1 then
		return candidate
	end

	return vim.fn.expand("~/.dotfiles")
end

local function expand_path(value)
	local home = vim.env.HOME or ""
	value = value:gsub("%${HOME}", home)
	value = value:gsub("%$HOME", home)
	return vim.fn.expand(value)
end

local tracked_paths

local function load_tracked_paths()
	if tracked_paths then
		return tracked_paths
	end

	tracked_paths = {}

	local file = io.open(inferred_root() .. "/paths.env", "r")
	if not file then
		return tracked_paths
	end

	for line in file:lines() do
		local trimmed = vim.trim(line)
		if trimmed ~= "" and not trimmed:match("^#") then
			local key, value = trimmed:match("^([A-Z0-9_]+)%s*=%s*(.-)%s*$")
			if key and value then
				local first = value:sub(1, 1)
				local last = value:sub(-1)
				if #value >= 2 and ((first == '"' and last == '"') or (first == "'" and last == "'")) then
					value = value:sub(2, -2)
				end
				tracked_paths[key] = expand_path(value)
			end
		end
	end

	file:close()
	return tracked_paths
end

function M.dotfiles_dir()
	if vim.env.DOTFILES_DIR and vim.fn.isdirectory(vim.env.DOTFILES_DIR) == 1 then
		return vim.env.DOTFILES_DIR
	end

	local tracked_dir = load_tracked_paths().DOTFILES_DIR
	if tracked_dir and vim.fn.isdirectory(tracked_dir) == 1 then
		return tracked_dir
	end

	return inferred_root()
end

function M.workflow_path(var, fallback)
	if vim.env[var] and vim.env[var] ~= "" then
		return vim.fn.expand(vim.env[var])
	end

	return load_tracked_paths()[var] or (fallback and vim.fn.expand(fallback) or nil)
end

function M.zotero_library_bib()
	return M.workflow_path("ZOTERO_LIBRARY_BIB", "~/Documents/Library/Library.bib")
end

return M
