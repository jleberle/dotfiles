" PLUGINS
" -------------------------------------------------------------------

"" VimWiki
""------------------------------------------------------------------
let g:vimwiki_global_ext = 0
let g:vimwiki_list = [
      \ {
      \         'path': '~/Git/wiki',
      \         'syntax': 'markdown',
      \         'ext': '.md',
      \         'template_ext': '.tpl',
      \         'html_filename_parameterization': 1,
      \         'auto_toc': 1},
      \ ]

"" Lightline
"" -------------------------------------------------------------------
set laststatus=2                            " always show a status line

if !has('gui_running')
  set t_Co=256
endif

let g:lightline = {
      \ 'colorscheme': 'solarized',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'gitbranch': 'fugitive#head'
      \ },
      \ }


"" Commentary.vim 
"" -------------------------------------------------------------------
autocmd FileType apache set commentstring=#\ %s   "comments for Apache
autocmd FileType make set commentstring=#\ %s   "comments for Makefile
autocmd FileType r set commentstring=#\ %s        "comments for R
autocmd FileType pandoc set commentstring=<!--\ %s\ -->   "comments for pandoc
nmap <C-c> gcc
vmap <C-c> gcc

"" Ctrl-P 
"" -------------------------------------------------------------------
let g:ctrlp_open_new_file = 'r'             " open new files in same window
nnoremap <C-B> :CtrlPBuffer<CR>
let g:ctrlp_use_caching = 0
let g:ctrlp_clear_cache_on_exit = 1         
let g:ctrlp_cache_dir = $HOME.'/.cache/ctrlp'
let g:ctrlp_dotfiles = 0                    " ignore dotfiles and dotdirs
let g:ctrlp_custom_ignore = { 'dir': '\.git$\|\_site$' }

"" SnipMate 
"" -------------------------------------------------------------------
let g:snipMate = { 'snippet_version' : 1 }
let g:netrw_dirhistmax=0
