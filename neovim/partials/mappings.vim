" Keyboard shortcuts
" -------------------------------------------------------------------
nmap ; :
nmap <leader>m :w<cr>
nnoremap ~ K
nnoremap K ~
nmap E ge
imap jj <Esc>

" reselect visual after indent
vnoremap < <gv
vnoremap > >gv

" move between splits
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
nnoremap ]<space> o<ESC>k
nnoremap ]N /\V[^\d\+]<CR>
nnoremap [N ?\V[^\d\+]<CR>

" Copying and pasting (Stopped working, see main settings for yank to system 
" clipboard setup. Leaving for reference
nnoremap <leader>0 "+p
vnoremap <leader>x "+y

"" Key mappings
"" -------------------------------------------------------------------

" Find the space before Pandoc footnotes
nnoremap <leader><space> /\v^$\n[\^1\]:<CR>:let @/ = ""<CR>

nnoremap <leader>v :silent !open -a Marked 2.app '%:p'<cr>:redraw!<cr>

nnoremap <silent> <leader>= mpgg/\v^(\w\|\#)<CR>=G`p :let @/ = ""<CR> " Clean up Pandoc with ,=

" Bibkeys Dictionary
set dictionary=$HOME/Documents/Bib/citekeys.txt
 set complete+=k

 " Expand directory of current file at command line
" http://vimcasts.org/episodes/the-edit-command/
cnoremap %% <C-R>=expand('%:h').'/'<cr>
map <leader>ew :e %%
map <leader>es :sp %%
map <leader>ev :vsp %%
map <leader>et :tabe %%

" Update/Reload Vimrc and Functions
" -------------------------------------------------------------------
command! -nargs=0 Evimrc e $MYVIMRC
command! -nargs=0 Svimrc source $MYVIMRC
command! -nargs=0 Efunctions e $HOME/.vim/functions.vim
nnoremap <silent> <leader>sz :call ToggleBackground()<cr>
" Tab completion
" -------------------------------------------------------------------
if has('wildmenu')
  set wildmenu
  set wildignore+=*.aux,*.bak,*.bbl,*.blg,*.class,*.doc,*.docx,*.dvi,*.fdb_latexmk,*.fls,*.idx,*.ilg,*.ind,*.out,*.png,*.pyc,*.Rout,*.rtf,*.swp,*.synctex.gz,*.toc,*/.hg/*,*/.svn/*,*.mp3,*/_site/*,*/_site-preview/*,*/_site-deploy/*,*~,.DS_Store,*/public/*,*Session.vim*,*.jpeg,*.jpg,*.gif,*.svg,*.log,*.lof,*.zip,*.pdf,*.md.tex,*/node_modules/*,*/lib/*,*data-raw/*,*legal-codes-split/*
  set suffixes+=*.log,*.zip,*.pdf
endif
