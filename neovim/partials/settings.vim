" Display
" -------------------------------------------------------------------
colorscheme nord
set nolist                                  " don't display space chars
set listchars=tab:▸\ ,eol:¬,trail:·,nbsp:·  " TextMate style space chars
set scrolloff=0
set number
" Resize the splits if the vim windows is resized
autocmd VimResized * :wincmd =

" General 
" -------------------------------------------------------------------
set showmatch
set showmode
set hidden
set history=1000                            " remember commands and searches
set undolevels=100                          " use many levels of undo
set noerrorbells                            " don't beep
set mouse=a                                 " use mouse in console
set nrformats-=octal
set shiftround
set timeoutlen=1000
set ttimeoutlen=0
au FocusLost * :wa                          " save when losing focus (gVim)

" Folding
" -------------------------------------------------------------------
set nofoldenable
set foldmethod=syntax
set foldcolumn=1
nnoremap <space> za

" Text formatting 
" -------------------------------------------------------------------
set tabstop=2                               " a tab is two spaces
set softtabstop=2                           " soft tab is two spaces
set shiftwidth=2                            " # of spaces for autoindenting
set expandtab                               " insert spaces not tabs
set copyindent                              " copy prev indentation
set shiftround                              " use shiftwidth when indenting

" Use Q to format paragraph
vnoremap Q gq
nnoremap Q gwap
set formatoptions=tqcwn                     " see :help fo-table

" Yank to system
set clipboard+=unnamed
" Pandoc 
" -------------------------------------------------------------------
au BufNewFile,BufFilePRe,BufRead *.markdown,*.md,*.mkd,*.pd,*.pdc,*.pdk,*.pandoc,*.text,*.txt,*.Rmd   set filetype=markdown.pandoc

" Find the space before Pandoc footnotes
nnoremap <leader><space> /\v^$\n[\^1\]:<CR>:let @/ = ""<CR>

" Search 
" -------------------------------------------------------------------
set path+=**
set ignorecase
set smartcase

" WRITING

"" Spell check 
"" -------------------------------------------------------------------
set spelllang=en_us                         " US English
set spell                                   " spell check on
set spellsuggest=10                         " only suggest a few words
