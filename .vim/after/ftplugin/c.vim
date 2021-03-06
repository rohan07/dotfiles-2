if has('cscope')
  set cscopetag
  set cscopetagorder=0
  set cscopeverbose
  "  s  symbol:   find all references to the token under cursor
  "  g  global:   find global definition(s) of the token under cursor
  "  c  calls:    find all calls to the function name under cursor
  "  t  text:     find all instances of the text under cursor
  "  e  egrep:    egrep search for the word under cursor
  "  f  file:     open the filename under cursor
  "  i  includes: find files that include the filename under cursor
  "  d  called:   find functions that function under cursor calls
  nnoremap <buffer> <leader>cs :cscope find s  <c-r>=expand('<cword>')<cr><cr>
  nnoremap <buffer> <leader>cg :cscope find g  <c-r>=expand('<cword>')<cr><cr>
  nnoremap <buffer> <leader>cc :cscope find c  <c-r>=expand('<cword>')<cr><cr>
  nnoremap <buffer> <leader>ct :cscope find t  <c-r>=expand('<cword>')<cr><cr>
  nnoremap <buffer> <leader>ce :cscope find e  <c-r>=expand('<cword>')<cr><cr>
  nnoremap <buffer> <leader>cf :cscope find f  <c-r>=expand('<cfile>')<cr><cr>
  nnoremap <buffer> <leader>ci :cscope find i ^<c-r>=expand('<cfile>')<cr>$<cr>
  nnoremap <buffer> <leader>cd :cscope find d  <c-r>=expand('<cword>')<cr><cr>
endif

function! s:make() abort
  silent! make
  redraw!
  cwindow
  wincmd p
  echo printf('Compiled.. %s (Time taken: %dm%2.2ds)',
        \ expand('%'),
        \ s:make_etime / 60,
        \ s:make_etime % 60)
endfunction

function! s:find_cscope_db() abort
  if !empty($CSCOPE_DB)
    return $CSCOPE_DB
  endif
  return findfile('cscope.out', '.;')
endfunction

function! s:add_cscope_db() abort
  let db = s:find_cscope_db()
  if empty(db)
    return
  endif
  silent cscope reset
  silent! execute 'cscope add' db
  let g:cscoped = db
endfunction

function! s:build_cscope_db(...) abort
  let db = s:find_cscope_db()
  if !empty(db) && filereadable(db)
    silent execute 'lcd' fnamemodify(db, ':h')
  endif
  let exts = empty(a:000)
        \ ? [ 'c', 'h', 'cc', 'hh', 'cpp', 'hpp', 'java' ]
        \ : a:000
  let cmd = "find . " . join(map(exts, "\"-name '*.\" . v:val . \"'\""), ' -o ')
  let tmp = tempname()
  try
    echon 'Building '. getcwd() .'/cscope.files.. '
    call system(cmd .'  > '. tmp)
    echon 'generating database.. '
    call system('cscope -b -q -i '. tmp)
    echon 'complete!'
    call s:add_cscope_db()
  finally
    silent! call delete(tmp)
  endtry
endfunction

let c_gnu            = 1
let c_no_curly_error = 1
let c_space_errors   = 1
let c_syntax_for_h   = 1

setlocal cinoptions  =>4,l1,p0,)50,*50,t0
setlocal comments    =sO:*\ -,mO:*\ \ ,exO:*/,s1:/*,mb:*,ex:*/
setlocal shiftwidth  =4
setlocal softtabstop =4

nnoremap <buffer> <F8>      :!clear && ./%:r<CR>
nnoremap <buffer> <F9>      :call <sid>make()<CR>
nnoremap <buffer> <leader>d ][V%{d

command! -bar -nargs=0 CSadd   call s:add_cscope_db()
command! -bar -nargs=* CSbuild call s:build_cscope_db(<f-args>)

autocmd QuickFixCmdPre  make let s:make_stime = localtime()
autocmd QuickFixCmdPost make let s:make_etime = localtime() - s:make_stime

if !filereadable('Makefile')
  compiler gcc
  if &filetype == 'c'
    let &l:makeprg = 'gcc -std=c11 -pedantic -Wall -Wextra -Wfloat-equal -ftrapv -o %:r %'
  elseif &ft == 'cpp'
    let &l:makeprg = "clang++ -std=c++11 -pedantic -Wall -Wextra -Weffc++ -o %:r %"
  endif
endif

CSadd
