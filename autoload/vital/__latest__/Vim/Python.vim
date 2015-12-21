let s:save_cpo = &cpo
set cpo&vim

let s:has_python2 = has('python')
let s:has_python3 = has('python3')
let s:current_major_version = 0
let s:default_major_version = 2

function! s:_throw(msg) abort
  throw printf('vital: Vim.Python: %s', a:msg)
endfunction

function! s:_get_valid_major_version(version) abort
  if a:version == 2 && !s:has_python2
    call s:_throw('+python is required')
  elseif a:version == 3 && !s:has_python3
    call s:_throw('+python3 is required')
  elseif !s:has_python2 && !s:has_python3
    call s:_throw('+python and/or +python3 is required')
  endif
  return a:version == 0
        \ ? s:current_major_version == 0
        \   ? s:default_major_version
        \   : s:current_major_version
        \ : a:version
endfunction


function! s:is_enabled() abort
  return s:has_python2 || s:has_python3
endfunction

function! s:get_major_version() abort
  if s:has_python2 && s:has_python3
    return s:_get_valid_major_version(s:current_major_version)
  elseif s:has_python2 || s:has_python3
    return s:has_python2 ? 2 : 3
  endif
  return 0
endfunction

function! s:set_major_version(version) abort
  let s:current_major_version = s:_get_valid_major_version(a:version)
endfunction

function! s:exec_file(path, ...) abort
  let major_version = s:_get_valid_major_version(get(a:000, 0, 0))
  if s:has_python2 && s:has_python3
    let exec = major_version == 2 ? 'pyfile' : 'py3file'
  else
    let exec = s:has_python2 ? 'pyfile' : 'py3file'
  endif
  return printf('%s %s', exec, a:path)
endfunction

function! s:exec_code(code, ...) abort
  let major_version = s:_get_valid_major_version(get(a:000, 0, 0))
  let code = type(a:code) == type('') ? a:code : join(a:code, "\n")
  if s:has_python2 && s:has_python3
    let exec = major_version == 2 ? 'python' : 'python3'
  else
    let exec = s:has_python2 ? 'python' : 'python3'
  endif
  return printf('%s %s', exec, code)
endfunction

if v:version >= 704 || (v:version == 703 && has('patch601'))
  function! s:eval_expr(expr, ...) abort
    let major_version = s:_get_valid_major_version(get(a:000, 0, 0))
    let expr = type(a:expr) == type('') ? a:expr : join(a:expr, "\n")
    if s:has_python2 && s:has_python3
      return major_version == 2 ? pyeval(expr) : py3eval(expr)
    else
      return s:has_python2 ? pyeval(expr) : py3eval(expr)
    endif
  endfunction
else
  function! s:eval_expr(expr, ...) abort
    call s:_throw('eval_expr() requires Vim 7.3.601 or later')
  endfunction
endif


let &cpo = s:save_cpo
unlet! s:save_cpo
" vim:set et ts=2 sts=2 sw=2 tw=0 fdm=marker:
