" Lua.Prelude
" Author: Tatsuhiro Ujihisa
"
"
" todo
" * If the vital dir has " this won't work.

let s:save_cpo = &cpo
set cpo&vim

let s:sfile = tr(expand('<sfile>:p'), '\', '/')

function! s:_vital_loaded(V) abort
  if has('lua')
    execute printf('lua vital_context = "%s"', s:sfile)
    call luaeval('dofile(_A)', s:luafile_of(s:sfile))
  else
    throw "Vital.Lua.Prelude: You don't have if_lua."
  endif
endfunction

function! s:plus(x, y) abort
  return luaeval('_G[_A[0]].vim.plus(_A[1], _A[2])', [s:sfile, a:x, a:y])
endfunction

" function! s:map(list, f) abort
"   return luaeval('_G[_A[0]].vim.map(_A[1], _A[2])', [s:sfile, a:list, a:f])
" endfunction
"
" " for testing
" function! s:mapinc(list) abort
"   return luaeval('_G[_A[0]].vim.map(_A[1], function(x) return x + 1 end)', [s:sfile, a:list])
" endfunction

function! s:lua_namespace() abort
  return s:sfile
endfunction

function! s:luafile_of(sfile) abort
  return substitute(tr(a:sfile, '\', '/'), '.vim$', '.lua', '')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
