local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
  -- Checked, because the first run of nvim on a new machine is also the most
  -- likely moment to have no network. Unchecked, a failed clone fell straight
  -- through to `require("lazy")`, which threw "module 'lazy' not found" on top
  -- of a stack trace -- that reads as "nvim is broken", not as "reconnect and
  -- open it again".
  if vim.v.shell_error ~= 0 then
    error(
      "Could not download lazy.nvim (the plugin manager), so no plugins can load.\n"
        .. "This is almost always no network connection.\n"
        .. "Reconnect and start nvim again -- nothing else is wrong.\n\n"
        .. "git said:\n"
        .. out
    )
  end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins")
