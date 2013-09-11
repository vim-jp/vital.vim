" TODO: move all comments to doc file.
"
"
" FIXME: This module name should be Vital.System ?
" But the name has been already taken.

let s:save_cpo = &cpo
set cpo&vim


" FIXME: Unfortunately, can't use s:_vital_loaded() for this purpose.
" Because these variables are used when this script file is loaded.
let s:is_windows = has('win16') || has('win32') || has('win64') || has('win95')
let s:is_unix = has('unix')


" Execute program in the background from Vim.
" Return an empty string always.
"
" If a:expr is a List, shellescape() each argument.
" If a:expr is a String, the arguments are passed as-is.
"
" Windows:
" Using :!start , execute program without via cmd.exe.
" Spawning 'expr' with 'noshellslash'
" keep special characters from unwanted expansion.
" (see :help shellescape())
"
" Unix:
" using :! , execute program in the background by shell.
function! s:spawn(expr, ...)
  if s:is_windows
    let shellslash = &l:shellslash
    setlocal noshellslash
  endif
  try
    if type(a:expr) is type([])
      let special = 1
      let cmdline = join(map(a:expr, 'shellescape(v:val, special)'), ' ')
    elseif type(a:expr) is type("")
      let cmdline = a:expr
      if a:0 && a:1
        let cmdline = substitute(cmdline, '\([!%#]\|<[^<>]\+>\)', '\\\1', 'g')
      endif
    else
      throw 'Process.spawn(): invalid argument (value type:'.type(a:expr).')'
    endif
    if s:is_windows
      silent execute '!start' cmdline
    else
      silent execute '!' cmdline '&'
    endif
  finally
    if s:is_windows
      let &l:shellslash = shellslash
    endif
  endtry
  return ''
endfunction

" iconv() wrapper for safety.
function! s:iconv(expr, from, to)
  if a:from == '' || a:to == '' || a:from ==? a:to
    return a:expr
  endif
  let result = iconv(a:expr, a:from, a:to)
  return result != '' ? result : a:expr
endfunction

" Check vimproc.
function! s:has_vimproc()
  if !exists('s:exists_vimproc')
    try
      call vimproc#version()
      let s:exists_vimproc = 1
    catch
      let s:exists_vimproc = 0
    endtry
  endif
  return s:exists_vimproc
endfunction

function! s:system(str, ...)
  let command = a:str
  let input = a:0 >= 1 ? a:1 : ''
  let command = s:iconv(command, &encoding, 'char')
  let input = s:iconv(input, &encoding, 'char')

  if a:0 == 0
    let output = s:has_vimproc() ?
          \ vimproc#system(command) : system(command)
  elseif a:0 == 1
    let output = s:has_vimproc() ?
          \ vimproc#system(command, input) : system(command, input)
  else
    " ignores 3rd argument unless you have vimproc.
    let output = s:has_vimproc() ?
          \ vimproc#system(command, input, a:2) : system(command, input)
  endif

  let output = s:iconv(output, 'char', &encoding)

  return output
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
