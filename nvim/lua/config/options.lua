local opt = vim.opt

vim.g.mapleader = " "

-- UI
opt.number = true
opt.relativenumber = false
opt.cursorline = false
opt.signcolumn = "yes"
opt.termguicolors = true
opt.scrolloff = 10
opt.sidescrolloff = 8

-- Splits
opt.splitbelow = true
opt.splitright = true

-- Share the macOS system clipboard (works with pbcopy/pbpaste, ghostty
-- copy-on-select, and tmux set-clipboard; crosses SSH via OSC 52)
opt.clipboard = "unnamedplus"

-- Search
opt.ignorecase = true
opt.smartcase = true

-- Timing
opt.updatetime = 250
opt.timeoutlen = 300

-- Undo
opt.undofile = true

-- Tabs
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2

-- Writing-focused
opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.textwidth = 80
opt.colorcolumn = "81"

-- spell / conceallevel are enabled per-filetype (see config/autocmds.lua) so
-- they don't fire spell underlines or hide characters in code buffers.
opt.spelllang = { "en_us" }

-- Better completion
opt.completeopt = "menu,menuone,noselect"

-- Use a POSIX shell for :!, system(), :terminal, and plugin shell-outs,
-- regardless of the login shell. Guards against a non-POSIX login shell
-- (e.g. fish) breaking plugins that pass POSIX command strings. This also
-- governs :terminal — to open an interactive fish there, run `:terminal fish`.
opt.shell = "/bin/sh"
