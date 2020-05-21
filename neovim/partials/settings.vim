" Vim File Locations 
" -------------------------------------------------------------------
set nobackup                                  " backups and swaps
set noswapfile
set backupdir=$HOME/.backups/vim/backup/
set directory=$HOME/.backups/vim/swap/

" General 
" -------------------------------------------------------------------
filetype plugin indent on
set encoding=utf-8
set showmatch
set showmode
set showcmd
set hidden
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
syntax enable
set notermguicolors
colorscheme neoSolarized 
set background=dark
set display+=lastline                       " show partial last lines
set nolist                                  " don't display space chars
set listchars=tab:▸\ ,eol:¬,trail:·,nbsp:·  " TextMate style space chars
set scrolloff=0
set number
" Resize the splits if the vim windows is resized
autocmd VimResized * :wincmd =

" Status line
" -------------------------------------------------------------------
set laststatus=2                            " always show a status line
set statusline=""
set statusline+=%t                          " tail/filename
set statusline+=%m%r%h                      " modified/read only/help
set statusline+=\ [%Y]                      " line endings/type of file
set statusline+=%=                          " left/right separator
"display a warning if &paste is set
set statusline+=%#error#
set statusline+=%{&paste?'[paste]':''}
set statusline+=%*
" display a warning if the line endings aren't unix
set statusline+=%#warningmsg#
set statusline+=%{&ff!='unix'?'['.&ff.']':''}
set statusline+=%*
" display a warning if file encoding isnt utf-8
set statusline+=%#warningmsg#
set statusline+=%{(&fenc!='utf-8'&&&fenc!='')?'['.&fenc.']':''}
set statusline+=%*
" progress through file
set statusline+=C:%02c,                       " cursor column
set statusline+=L:%03l/%03L                   " cursor line/total lines
set statusline+=\ %P                        " percent through file

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

" Pandoc 
" -------------------------------------------------------------------
au BufNewFile,BufFilePRe,BufRead *.markdown,*.md,*.mkd,*.pd,*.pdc,*.pdk,*.pandoc,*.text,*.txt,*.Rmd   set filetype=markdown.pandoc
" Find the space before Pandoc footnotes
nnoremap <leader><space> /\v^$\n[\^1\]:<CR>:let @/ = ""<CR>

" Search 
" -------------------------------------------------------------------
set incsearch
set ignorecase
set smartcase

" WRITING

"" Spell check 
"" -------------------------------------------------------------------
set spelllang=en_us                         " US English
set spell                                   " spell check on
set spellsuggest=10                         " only suggest a few words