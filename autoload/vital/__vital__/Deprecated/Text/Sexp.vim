" Deprecated.Text.Sexp
" Author: Tatsuhiro Ujihisa

let s:save_cpo = &cpo
set cpo&vim

let s:sfile = expand('<sfile>:p')

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:P = s:V.import('Deprecated.Lua.Prelude')
  let s:LuaP = s:P.lua_namespace()

  if exists('*luaeval')
    execute printf('lua vital_context = "%s"', escape(s:sfile, '\'))
    if has('patch-8.1.0672')
      call luaeval('nil,dofile(_A)', substitute(s:sfile, '.vim$', '.lua', ''))
    else
      call luaeval('0,dofile(_A)', substitute(s:sfile, '.vim$', '.lua', ''))
    endif
  endif
endfunction

function! s:_vital_depends() abort
  return {
  \   'modules': ['Deprecated.Lua.Prelude'],
  \   'files': ['./Sexp.lua'],
  \ }
endfunction

" lua array index as 0 based.
let s:_base = 0
if has('patch-8.2.1066')
  " fix lua array index as 1 based.
  let s:_base = 1
endif
function! s:_index(idx) abort
  return printf('%d', s:_base + a:idx)
endfunction

function! s:parse(sexp) abort
  if exists('*luaeval')
    return luaeval('_G[_A[' . s:_index(0) . ']].vim.parse(_A[' .  s:_index(1)  . '])', [s:sfile, a:sexp])
    " return luaeval('_G[_A[0]].vim.parse(_A[1])', [s:sfile, a:sexp])
    " return luaeval('vital_text_sexp.parse(_A)', a:sexp)
    " return luaeval('vital_text_sexp.parse(vital_text_sexp.parse(_A))', a:sexp)
  else
    throw 'vital: Deprecated.Text.Sexp: any function call needs if_lua'
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim:set et ts=2 sts=2 sw=2 tw=0:
