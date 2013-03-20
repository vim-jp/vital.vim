" FIXME: This module name should be Vital.System ?
" But the name has been already taken.

let s:save_cpo = &cpo
set cpo&vim


" FIXME: Unfortunately, can't use s:_vital_loaded() for this purpose.
" Because these variables are used when this script file is loaded.
let s:is_windows = has('win16') || has('win32') || has('win64') || has('win95')
let s:is_unix = has('unix')


" Run an application in the background from Vim.
" Return an empty string always.
"
" Windows:
" If a:expr is a List or a String,
" using :!start , run an application bypassing cmd.exe.
"
" Unix:
" If a:expr is a List, shellescape() each argument.
" If a:expr is a String, just pass the argument to system().
if s:is_windows
  function! s:spawn(expr)
    let cmdline = a:expr
    if type(a:expr) is type([])
      let cmdline = join(a:expr, ' ')
    elseif type(a:expr) is type("")
      let cmdline = a:expr
    else
      throw 'Process.spawn(): invalid argument (value type:'.type(a:expr).')'
    endif

    " Escape:
    " * cmdline-special (:help cmdline-special, :help expand())
    " * '!' (:help :!)
    let pat = '[%#<>!]'
    let sub = '\\\0'
    let cmdline = substitute(cmdline, pat, sub, "g")
    " Spawning 'expr' with 'noshellslash'
    " avoids above characters' expansion. (e.g., '\' -> '/')
    let shellslash = &l:shellslash
    setlocal noshellslash
    try
      execute '!start' cmdline
    finally
      let &l:shellslash = shellslash
    endtry
    return ''
  endfunction

elseif s:is_unix
  function! s:spawn(expr)
    let cmdline = a:expr
    if type(a:expr) is type([])
      let cmdline = join(shellescape(a:expr), ' ')
    elseif type(a:expr) is type("")
      let cmdline = a:expr
    else
      throw 'Process.spawn(): invalid argument (value type:'.type(a:expr).')'
    endif

    let cmdline = cmdline.(cmdline =~# '&\s*$' ? '' : ' &')
    call system(cmdline)
    return ''
  endfunction

else
  " XXX: Should :throw when this script file is loaded?
  function! s:spawn(expr)
    throw 'Process.spawn(): does not support your platform.'
  endfunction
endif


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
