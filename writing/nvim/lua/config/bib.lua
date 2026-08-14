-- Citation picker over the Zotero library, replacing telescope-bibtex (whose
-- last commit was in 2024). The library is a Better BibTeX auto-export, so the
-- shape is predictable: one field per line, no wrapped values. That makes a
-- line parser sufficient -- and at ~240 entries there is nothing here that
-- needs a plugin's indexing.
--
-- Stays on the .bib rather than the .json pandoc renders from: the .bib is what
-- Better BibTeX keeps in sync, and its citekeys are the ones pandoc resolves.
local paths = require("config.paths")

local M = {}

-- Better BibTeX wraps values in braces, and doubles them ({{Wounded Knee}})
-- around proper nouns to protect capitalization. Both are noise in a picker.
local function clean(value)
	value = vim.trim(value):gsub(",%s*$", "")
	return vim.trim((value:gsub("[{}]", "")))
end

local FIELDS = { "author", "editor", "year", "title" }

local function entries()
	local bib = paths.zotero_library_bib()
	if vim.fn.filereadable(bib) ~= 1 then
		vim.notify("No BibTeX library at " .. bib, vim.log.levels.WARN)
		return {}
	end

	local parsed, current = {}, nil
	for line in io.lines(bib) do
		local key = line:match("^@%w+%s*{%s*([^,]+),")
		if key then
			if current then
				table.insert(parsed, current)
			end
			current = { key = key }
		elseif current then
			for _, field in ipairs(FIELDS) do
				if not current[field] then
					local value = line:match("^%s*" .. field .. "%s*=%s*(.*)$")
					if value then
						current[field] = clean(value)
					end
				end
			end
		end
	end
	if current then
		table.insert(parsed, current)
	end
	return parsed
end

-- "Smith, John and Doe, Jane" -> "Smith et al."; the archival items carry no
-- author at all, so fall back to editor and then to a placeholder.
local function creator(entry)
	local name = entry.author or entry.editor
	if not name or name == "" then
		return "—"
	end
	local first = name:match("^([^,]+)") or name
	if name:find(" and ") then
		return first .. " et al."
	end
	return first
end

-- One padded line per entry. mini.pick matches against the whole line, so
-- "wounded" finds items by title and "brown 2007" narrows by author and year --
-- not just by the citekey you have to remember.
local function format(entry)
	return string.format("%-28s %-22s %-6s %s", entry.key, creator(entry), entry.year or "n.d.", entry.title or "")
end

function M.pick()
	local items = {}
	for _, entry in ipairs(entries()) do
		table.insert(items, { text = format(entry), key = entry.key })
	end

	-- Read the mode before the picker opens: inside it we are always in the
	-- prompt's insert mode. Called from insert mode the key goes before the
	-- cursor and we return to insert; from normal mode it goes after, like `p`.
	-- This is what telescope-bibtex did.
	local inserting = vim.api.nvim_get_mode().mode:sub(1, 1) == "i"

	require("mini.pick").start({
		source = {
			name = "Citations",
			items = items,
			-- `choose` runs while the picker window is still current, so the
			-- put has to wait until it has closed.
			choose = function(item)
				if not item then
					return
				end
				vim.schedule(function()
					vim.api.nvim_put({ "@" .. item.key }, "", not inserting, true)
					if inserting then
						vim.api.nvim_feedkeys("a", "n", true)
					end
				end)
			end,
		},
	})
end

return M
