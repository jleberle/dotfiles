 " Neovim configuration

" Plugins
" -------------------------------------------------------------------

call plug#begin('~/.local/share/nvim/plugged')

Plug 'ctrlpvim/ctrlp.vim'
Plug 'icymind/NeoSolarized'

Plug 'tpope/vim-commentary'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-fugitive'

Plug 'vim-pandoc/vim-pandoc'
Plug 'vim-pandoc/vim-pandoc-syntax'
Plug 'vim-pandoc/vim-markdownfootnotes'

Plug 'itchyny/lightline.vim'

Plug 'vimwiki/vimwiki'
Plug 'mattn/calendar-vim'

Plug 'garbas/vim-snipmate'
Plug 'honza/vim-snippets' " Defaults
Plug 'marcweber/vim-addon-mw-utils' " Required by Snipmate
Plug 'tomtom/tlib_vim' " Required by Snipmate

call plug#end()

let mapleader = ","
let maplocalleader = ","

set termguicolors

runtime! partials/settings.vim
runtime! partials/plugins.vim
runtime! partials/mappings.vim
runtime! partials/filetype/*.vim
runtime! partials/functions.vim
