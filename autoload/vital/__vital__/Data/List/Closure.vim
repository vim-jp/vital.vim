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
  try
    return s:List.map(a:xs, function('s:_provide_unary_callable'))
  finally
    unlet s:unary_closure_func
  endtry
endfunction

function! s:foldl(callable, x, xs) abort
  let s:binary_closure_func = a:callable
  try
  return s:List.foldl(function('s:_provide_binary_callable'), a:x, a:xs)
  finally
    unlet s:binary_closure_func
  endtry
endfunction

function! s:foldl1(callable, xs) abort
  let s:binary_closure_func = a:callable
  try
    return s:List.foldl1(function('s:_provide_binary_callable'), a:xs)
  finally
    unlet s:binary_closure_func
  endtry
endfunction

function! s:foldr(callable, x, xs) abort
  let s:binary_closure_func = a:callable
  try
    return s:List.foldr(function('s:_provide_binary_callable'), a:x, a:xs)
  finally
    unlet s:binary_closure_func
  endtry
endfunction

function! s:foldr1(callable, xs) abort
  let s:binary_closure_func = a:callable
  try
    return s:List.foldr1(function('s:_provide_binary_callable'), a:xs)
  finally
    unlet s:binary_closure_func
  endtry
endfunction

function! s:uniq_by(xs, callable) abort
  let s:unary_closure_func = a:callable
  try
    return s:List.uniq_by(a:xs, function('s:_provide_unary_callable'))
  finally
    unlet s:unary_closure_func
  endtry
endfunction

function! s:max_by(xs, callable) abort
  let s:unary_closure_func = a:callable
  try
    return s:List.max_by(a:xs, function('s:_provide_unary_callable'))
  finally
    unlet s:unary_closure_func
  endtry
endfunction

function! s:min_by(xs, callable) abort
  let s:unary_closure_func = a:callable
  try
    return s:List.min_by(a:xs, function('s:_provide_unary_callable'))
  finally
    unlet s:unary_closure_func
  endtry
endfunction

function! s:span(callable, xs) abort
  let s:unary_closure_func = a:callable
  try
    return s:List.span(function('s:_provide_unary_callable'), a:xs)
  finally
    unlet s:unary_closure_func
  endtry
endfunction

function! s:break(callable, xs) abort
  let s:unary_closure_func = a:callable
  try
    return s:List.break(function('s:_provide_unary_callable'), a:xs)
  finally
    unlet s:unary_closure_func
  endtry
endfunction

function! s:take_while(callable, xs) abort
  let s:unary_closure_func = a:callable
  try
    return s:List.take_while(function('s:_provide_unary_callable'), a:xs)
  finally
    unlet s:unary_closure_func
  endtry
endfunction

function! s:drop_while(callable, xs) abort
  let s:unary_closure_func = a:callable
  try
    return s:List.drop_while(function('s:_provide_unary_callable'), a:xs)
  finally
    unlet s:unary_closure_func
  endtry
endfunction

function! s:sort(xs, callable) abort
  let s:binary_closure_func = a:callable
  try
    return s:List.sort(a:xs, function('s:_provide_binary_callable'))
  finally
    unlet s:binary_closure_func
  endtry
endfunction

function! s:sort_by(xs, callable) abort
  let s:unary_closure_func = a:callable
  try
    return s:List.sort_by(a:xs, function('s:_provide_unary_callable'))
  finally
    unlet s:unary_closure_func
  endtry
endfunction

function! s:all(callable, xs) abort
  let s:unary_closure_func = a:callable
  try
    return s:List.all(function('s:_provide_unary_callable'), a:xs)
  finally
    unlet s:unary_closure_func
  endtry
endfunction

function! s:any(callable, xs) abort
  let s:unary_closure_func = a:callable
  try
    return s:List.any(function('s:_provide_unary_callable'), a:xs)
  finally
    unlet s:unary_closure_func
  endtry
endfunction

function! s:partition(callable, xs) abort
  let s:unary_closure_func = a:callable
  try
    return s:List.partition(function('s:_provide_unary_callable'), a:xs)
  finally
    unlet s:unary_closure_func
  endtry
endfunction

function! s:map_accum(callable, xs, init) abort
  let s:binary_closure_func = a:callable
  try
    return s:List.map_accum(function('s:_provide_binary_callable'), a:xs, a:init)
  finally
    unlet s:binary_closure_func
  endtry
endfunction

function! s:find(xs, default, callable) abort
  let s:unary_closure_func = a:callable
  try
    return s:List.find(a:xs, a:default, function('s:_provide_unary_callable'))
  finally
    unlet s:unary_closure_func
  endtry
endfunction

function! s:find_index(xs, callable, ...) abort
  let s:unary_closure_func = a:callable
  try
    return call(s:List.find_index, [a:xs, function('s:_provide_unary_callable')] + a:000)
  finally
    unlet s:unary_closure_func
  endtry
endfunction

function! s:find_last_index(xs, callable, ...) abort
  let s:unary_closure_func = a:callable
  try
    return call(s:List.find_last_index, [a:xs, function('s:_provide_unary_callable')] + a:000)
  finally
    unlet s:unary_closure_func
  endtry
endfunction

function! s:find_indices(xs, callable, ...) abort
  let s:unary_closure_func = a:callable
  try
    return call(s:List.find_indices, [a:xs, function('s:_provide_unary_callable')] + a:000)
  finally
    unlet s:unary_closure_func
  endtry
endfunction

function! s:group_by(xs, callable) abort
  let s:unary_closure_func = a:callable
  try
    return s:List.group_by(a:xs, function('s:_provide_unary_callable'))
  finally
    unlet s:unary_closure_func
  endtry
endfunction

function! s:binary_search(xs, target, callable) abort
  let s:binary_closure_func = a:callable
  try
    return s:List.binary_search(a:xs, a:target, function('s:_provide_binary_callable'))
  finally
    unlet s:binary_closure_func
  endtry
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
