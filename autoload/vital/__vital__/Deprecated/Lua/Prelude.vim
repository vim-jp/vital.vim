" Deprecated.Lua.Prelude
" Author: Tatsuhiro Ujihisa
"
"
" todo
" * If the vital dir has " this won't work.

let s:save_cpo = &cpo
set cpo&vim

let s:sfile = tr(expand('<sfile>:p'), '\', '/')

" @vimlint(EVL103, 1, a:V)
function! s:_vital_loaded(V) abort
  if exists('*luaeval')
    execute printf('lua vital_context = "%s"', s:sfile)
    if has('patch-8.1.0672')
      call luaeval('nil,dofile(_A)', s:luafile_of(s:sfile))
    else
      call luaeval('0,dofile(_A)', s:luafile_of(s:sfile))
    endif
  endif
endfunction
" @vimlint(EVL103, 0, a:V)

function! s:_vital_depends() abort
  return {
  \   'files': ['./Prelude.lua']
  \ }
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
