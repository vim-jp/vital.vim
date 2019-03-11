let s:save_cpo = &cpo
set cpo&vim

let s:current_major_version = 0

function! s:_throw(msg) abort
  throw printf('vital: Vim.Python: %s', a:msg)
endfunction

function! s:_get_valid_major_version(version) abort
  if index([0, 2, 3], a:version) == -1
    call s:_throw('"version" requires to be 0, 2, or 3')
  elseif a:version == 2 && !s:is_python2_enabled()
    call s:_throw('+python is required')
  elseif a:version == 3 && !s:is_python3_enabled()
    call s:_throw('+python3 is required')
  elseif !s:is_enabled()
    call s:_throw('+python and/or +python3 is required')
  endif
  return a:version == 0
        \ ? s:current_major_version == 0
        \   ? s:is_python2_enabled()
        \     ? 2
        \     : 3
        \   : s:current_major_version
        \ : a:version
endfunction


function! s:is_enabled() abort
  return s:is_python2_enabled() || s:is_python3_enabled()
endfunction
function! s:is_python2_enabled() abort
  if exists('s:is_python2_enabled')
    return s:is_python2_enabled
  endif
  try
    if !has('python')
      let s:is_python2_enabled = 0
    else
      python 0
      let s:is_python2_enabled = 1
    endif
  catch /^Vim(python):/
    let s:is_python2_enabled = 0
  catch /^Vim\%((\a\+)\)\=:\%(E263\|E264\|E887\):/
    let s:is_python2_enabled = 0
  endtry
  return s:is_python2_enabled
endfunction
function! s:is_python3_enabled() abort
  if exists('s:is_python3_enabled')
    return s:is_python3_enabled
  endif
  try
    if !has('python3')
      let s:is_python3_enabled = 0
    else
      python3 0
      let s:is_python3_enabled = 1
    endif
  catch /^Vim(python3):/
    let s:is_python3_enabled = 0
  catch /^Vim\%((\a\+)\)\=:\%(E263\|E264\|E887\):/
    let s:is_python3_enabled = 0
  endtry
  return s:is_python3_enabled
endfunction

function! s:get_major_version() abort
  if s:is_python2_enabled() && s:is_python3_enabled()
    return s:_get_valid_major_version(s:current_major_version)
  elseif s:is_enabled()
    return s:is_python2_enabled() ? 2 : 3
  endif
  return 0
endfunction

function! s:set_major_version(version) abort
  let s:current_major_version = s:_get_valid_major_version(a:version)
endfunction

function! s:exec_file(path, ...) abort
  let major_version = s:_get_valid_major_version(get(a:000, 0, 0))
  if s:is_python2_enabled() && s:is_python3_enabled()
    let exec = major_version == 2 ? 'pyfile' : 'py3file'
  else
    let exec = s:is_python2_enabled() ? 'pyfile' : 'py3file'
  endif
  return printf('%s %s', exec, a:path)
endfunction

function! s:exec_code(code, ...) abort
  let major_version = s:_get_valid_major_version(get(a:000, 0, 0))
  let code = type(a:code) == type('') ? a:code : join(a:code, "\n")
  if s:is_python2_enabled() && s:is_python3_enabled()
    let exec = major_version == 2 ? 'python' : 'python3'
  else
    let exec = s:is_python2_enabled() ? 'python' : 'python3'
  endif
  return printf('%s %s', exec, code)
endfunction

function! s:eval_expr(expr, ...) abort
  let major_version = s:_get_valid_major_version(get(a:000, 0, 0))
  let expr = type(a:expr) == type('') ? a:expr : join(a:expr, "\n")
  if s:is_python2_enabled() && s:is_python3_enabled()
    return major_version == 2 ? pyeval(expr) : py3eval(expr)
  else
    return s:is_python2_enabled() ? pyeval(expr) : py3eval(expr)
  endif
endfunction


let &cpo = s:save_cpo
unlet! s:save_cpo
" vim:set et ts=2 sts=2 sw=2 tw=0 fdm=marker:
