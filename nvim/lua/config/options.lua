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

opt.spell = true
opt.spelllang = { "en_us" }

opt.conceallevel = 2

-- Better completion
opt.completeopt = "menu,menuone,noselect"
