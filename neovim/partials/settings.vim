" Vim File Locations 
" -------------------------------------------------------------------
set backup                                  " backups and swaps
set swapfile
set backupdir=$HOME/.backups/vim/backup/
set directory=$HOME/.backups/vim/swap/

" General 
" -------------------------------------------------------------------
set encoding=utf-8
set showmode
set showcmd
set hidden
set showmatch
set ruler
set backspace=indent,eol,start              " allow backspacing in insert mode
set smarttab
set history=1000                            " remember commands and searches
set undolevels=100                          " use many levels of undo
set noerrorbells                            " don't beep
set mouse=a                                 " use mouse in console
set nrformats-=octal
set shiftround
set timeoutlen=1000
set ttimeoutlen=0
set autoread
au FocusLost * :wa                          " save when losing focus (gVim)

" General Display
" -------------------------------------------------------------------
set display+=lastline                       " show partial last lines
set nolist                                  " don't display space chars
set listchars=tab:▸\ ,eol:¬,trail:·,nbsp:·  " TextMate style space chars
set scrolloff=0
set number
" Resize the splits if the vim windows is resized
autocmd VimResized * :wincmd =

" Folding
" -------------------------------------------------------------------
set nofoldenable
set foldcolumn=1
nnoremap <space> za

" Text formatting 
" -------------------------------------------------------------------
set tabstop=2                               " a tab is two spaces
set softtabstop=2                           " soft tab is two spaces
set shiftwidth=2                            " # of spaces for autoindenting
set expandtab                               " insert spaces not tabs
set autoindent                              " always set autoindenting on
set copyindent                              " copy prev indentation
set shiftround                              " use shiftwidth when indenting
" Use Q to format paragraph
vnoremap Q gq
nnoremap Q gwap
set formatoptions=tqcwn                     " see :help fo-table

" Search 
" -------------------------------------------------------------------
set incsearch
set ignorecase
set smartcase

" WRITING

"" Spell check 
"" -------------------------------------------------------------------
set spellsuggest=10                         " only suggest a few words
