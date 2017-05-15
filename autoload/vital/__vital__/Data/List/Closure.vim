let s:save_cpo = &cpo
set cpo&vim


function! s:_vital_loaded(V) abort
  let s:Closure = a:V.import('Data.Closure')
  let s:List    = a:V.import('Data.List')
endfunction

function! s:_vital_depends() abort
  return ['Data.Closure', 'Data.List']
endfunction


function! s:map(xs, callable) abort
  let s:unary_closure_func = a:callable
  return s:List.map(a:xs, function('s:_provide_unary_callable'))
endfunction

function! s:foldl(callable, x, xs) abort
  let s:binary_closure_func = a:callable
  return s:List.foldl(function('s:_provide_binary_callable'), a:x, a:xs)
endfunction


" Notice:
" This is not job safe.
" The function may not work correctly.
function! s:_provide_unary_callable(x) abort
  return s:Closure.apply(s:unary_closure_func, [a:x])
endfunction

" Notice:
" This is not job safe.
" The function may not work correctly.
function! s:_provide_binary_callable(x, y) abort
  return s:Closure.apply(s:binary_closure_func, [a:x, a:y])
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:ts=2:sw=2:et
