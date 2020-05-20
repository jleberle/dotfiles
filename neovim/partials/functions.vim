" With a file `test.md` in the current Vim buffer, open the file `test.md.pdf` in the OS.
" https://gist.github.com/lmullen/b7231f5ce79eba9c6aeb
command! -nargs=0 PDF call PDF()
function! PDF()
    :silent exec "!open ".expand("%:p").".pdf"
endfunction

" Find related Pandoc footnote numbers
" -------------------------------------------------------------------
" Vim's * key searches for the next instance of the word under the 
" cursor; Vim decides what counts as the boundary of a word with the 
" iskeyword option. This function toggles the special characters of a 
" Pandoc footnote in the form [^1] to allow you to jump between 
" footnotes with the * key.
nnoremap _fn :call ToggleFootnoteJumping()<CR>
function! ToggleFootnoteJumping()
  if exists("g:FootnoteJumping") 
    if g:FootnoteJumping == 1
      set iskeyword-=[
      set iskeyword-=]
      set iskeyword-=^
      let g:FootnoteJumping = 0
    else
      set iskeyword+=[
      set iskeyword+=]
      set iskeyword+=^
      let g:FootnoteJumping = 1
    endif
  else 
    set iskeyword+=[
    set iskeyword+=]
    set iskeyword+=^
    let g:FootnoteJumping = 1
  endif
endfunction

" Find text markers
nnoremap <leader>{ :vimgrep /{\w\+}/ %<CR>:copen<CR>

" Strip trailing white space (`_sw`)
function! StripWhitespace()
    let save_cursor = getpos(".")
    let old_query = getreg('/')
    :%s/\s\+$//e
    call setpos('.', save_cursor)
    call setreg('/', old_query)
endfunction
noremap _sw :call StripWhitespace()<CR>

" convert smart typographical symbols to Markdown standards
nnoremap _md :silent! call CleanMarkdown()<CR>
function! CleanMarkdown()
  :%s/—/---/ge 
  :%s/–/--/ge
  :%s/…/.../ge
  :%s/’/'/ge
  :%s/“/"/ge
  :%s/‘/'/ge
  :%s/”/"/ge
  :%s/
//ge
  :%s/``/"/ge
  :%s/''/"/ge
  " The space replaced below is a non-breaking space commonly used before the 
  " colon in a title in library catalogs. It breaks pdfLaTeX.
  :%s/ :/:/ge
endfunction

" put an en dash between number ranges
nnoremap _en :call EnDashRange()<CR>
function! EnDashRange()
  :%s/\v(\d)-(\d)/\1--\2/ge
endfunction

command! -nargs=0 BG call ToggleBackground()
function! ToggleBackground()
  if &background == "dark"
    set background=light
  else
    set background=dark
  endif
endfunction


" Navigate to a Pandoc footnote 
command! -nargs=* Fn call GoToFootnote(<f-args>)
function! GoToFootnote(footnote, ...)
  let definition = ''
  if a:0 > 0
    let definition = a:1
  endif
  call search('\[\^' . a:footnote . '\]' . definition)
endfunction

" Abbreviate months
command! -nargs=0 AbbreviateMonths call AbbreviateMonths()
function! AbbreviateMonths()
  :%s/January/Jan./g
  :%s/February/Feb./g
  :%s/March/Mar./g
  :%s/April/Apr./g
  :%s/May/May/g
  :%s/June/June/g
  :%s/July/July/g
  :%s/August/Aug./g
  :%s/September/Sept./g
  :%s/October/Oct./g
  :%s/November/Nov./g
  :%s/December/Dec./g
endfunction

" Command to call Pandoc and process working file, using functions below
command! -nargs=* Pan execute ":call Pan<args>()"
nmap <leader>p :Pan 

" Functions to pass file through pandoc

function! PanPdf()
   exec ":! pandoc -o ~/Desktop/" . fnameescape(expand('%:t:r')) . ".pdf " . fnameescape(expand('%:p'))
endfunction

function! PanRtf()
   exec ":! pandoc -s -S -t rtf -o ~/Desktop/" . fnameescape(expand('%:t:r')) . ".rtf " . fnameescape(expand('%:p'))
endfunction

function! PanSyllabus()
   exec ":! pandoc -s -S --template=syllabus.tex -o ~/Desktop/" . fnameescape(expand('%:t:r')) . ".pdf " . fnameescape(expand('%:p'))
endfunction

function! PanDocx()
   exec ":! makebib;pandoc -s -S -t docx --reference-docx=/Users/wcm1/.pandoc/reference.docx --bibliography=/Users/wcm1/all.bib -o ~/Desktop/" . fnameescape(expand('%:t:r')) . ".docx " . fnameescape(expand('%:p'))
endfunction

function! PanBib()
   exec ":! makebib;pandoc -s -S -t markdown --bibliography=/Users/wcm1/all.bib . fnameescape(expand('%:p'))"
endfunction
