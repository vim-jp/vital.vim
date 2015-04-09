" Text.Sexp
" Author: Tatsuhiro Ujihisa

let s:save_cpo = &cpo
set cpo&vim

let s:sfile = expand('<sfile>:p')

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:P = s:V.import('Lua.Prelude')
  let s:LuaP = s:P.lua_namespace()

  if has('lua')
    execute printf('lua vital_context = "%s"', s:sfile)
    call luaeval('dofile(_A)', substitute(s:sfile, '.vim$', '.lua', ''))
  else
    throw "Vital.Text.Sexp: You don't have if_lua."
  endif
endfunction

function! s:_vital_depends() abort
  return ['Lua.Prelude']
endfunction

function! s:parse(sexp) abort
  if has('lua')
    return luaeval('_G[_A[0]].vim.parse(_A[1])', [s:sfile, a:sexp])
    " return luaeval('vital_text_sexp.parse(_A)', a:sexp)
    " return luaeval('vital_text_sexp.parse(vital_text_sexp.parse(_A))', a:sexp)
  else
    throw 'Text.Sexp: any function call needs if_lua'
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim:set et ts=2 sts=2 sw=2 tw=0:
