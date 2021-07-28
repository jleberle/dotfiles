 " Neovim configuration
" Plugins
" -------------------------------------------------------------------
call plug#begin('~/.local/share/nvim/plugged')

Plug 'ctrlpvim/ctrlp.vim' " Find Files
Plug 'arcticicestudio/nord-vim' " Theme
Plug 'tpope/vim-commentary' " Comment out lines 
Plug 'tpope/vim-eunuch' " UNIX Shell Commands
Plug 'tpope/vim-unimpaired' " Mostly use for the space command [<space> and ]<space>
Plug 'tpope/vim-fugitive' " Git wrapper

Plug 'vim-pandoc/vim-pandoc' " Pandoc commands
Plug 'vim-pandoc/vim-pandoc-syntax' "Pandoc syntax
Plug 'vim-pandoc/vim-markdownfootnotes' " Add footnotes <leader>-f and exit back to body <leader-r>
Plug 'robertbasic/vim-hugo-helper' " Hugo command helper

Plug 'itchyny/lightline.vim' " Info bar

Plug 'garbas/vim-snipmate' "Snipmate
Plug 'honza/vim-snippets' " Defaults
Plug 'marcweber/vim-addon-mw-utils' " Required by Snipmate
Plug 'tomtom/tlib_vim' " Required by Snipmate

call plug#end()

let mapleader = "," " Use , instead of :
let maplocalleader = "," " Use , instead of :

" Source files to make finding stuff easier
runtime! partials/settings.vim
runtime! partials/plugins.vim
runtime! partials/mappings.vim
runtime! partials/filetype/*.vim
runtime! partials/functions.vim
