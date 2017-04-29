let s:save_cpo = &cpo
set cpo&vim


function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:List = s:V.import('Data.List')
endfunction

function! s:_vital_depends() abort
  return ['Data.List']
endfunction


" --- private objects --- "

" This value is regarded to an unique value in the future
let s:_NOTHING = tempname() | lockvar s:_NOTHING

" Return call of Funcref or String expression
function! s:_get_caller(f) abort
  return type(a:f) is type(function('function'))
  \      ? function('call')
  \      : function('s:_call_string_expr')
endfunction

function! s:_call_string_expr(expr, args) abort
  return map([a:args[0]], a:expr)[0]
endfunction


" --- public objects --- "

function! s:left(x) abort
  return [a:x, s:_NOTHING]
endfunction


function! s:right(y) abort
  return [s:_NOTHING, a:y]
endfunction


function! s:is_left(either) abort
  try
    " These are named by Pascal Case because it maybe the function
    let l:MayNotBeRight = a:either[1]
    "TODO: Test is failed if l:result is removed
    let l:result = l:MayNotBeRight ==# s:_NOTHING
    return l:result
  catch /\(E714\|E716\|E691\|E692\|E693\)/
    return 0
  endtry
endfunction


function! s:is_right(either) abort
  try
    let l:MayNotBeRight = a:either[0]
    "TODO: Test is failed if l:result is removed
    let l:result = l:MayNotBeRight ==# s:_NOTHING
    return l:result
  catch /\(E714\|E716\|E691\|E692\|E693\)/
    return 0
  endtry
endfunction


function! s:is_either(x) abort
  return s:is_left(a:x) || s:is_right(a:x)
endfunction


function! s:unsafe_from_left(either) abort
  if s:is_right(a:either)
    throw 'vital: Data.Either: from_left() cannot be applied by right value'
  endif
  let [l:X, _] = a:either
  return l:X
endfunction


function! s:unsafe_from_right(either) abort
  if s:is_left(a:either)
    throw 'vital: Data.Either: from_right() cannot be applied by left value'
  endif
  let [_, l:Y] = a:either
  return l:Y
endfunction


function! s:from_left(default, either) abort
  return s:is_left(a:either) ? s:unsafe_from_left(a:either)
  \                          : a:default
endfunction


function! s:from_right(default, either) abort
  return s:is_right(a:either) ? s:unsafe_from_right(a:either)
  \                           : a:default
endfunction


function! s:map(either, f) abort
  if s:is_left(a:either)
    return a:either
  endif
  let l:internal  = s:unsafe_from_right(a:either)
  let l:internal_ = s:_get_caller(a:f)(a:f, [l:internal])

  return s:right(l:internal_)
endfunction


function! s:apply(either_func, ...) abort
  if s:is_left(a:either_func)
    return a:either_func
  endif
  let l:either_values = a:000

  "TODO: Use function('s:is_left') instead when s:List.find() corresponded Funcref
  function! IsLeftOfEither(either) abort
    return s:is_left(a:either)
  endfunction
  "TODO: Use lambda instead when vital.vim remove vim7.4 support
  function! UnsafeFromRightOfEither(either) abort
    return s:unsafe_from_right(a:either)
  endfunction
  try
    let l:NULL         = 0 | lockvar l:NULL
    let l:null_or_left = s:List.find(l:either_values, l:NULL, 'IsLeftOfEither(v:val)')
    if l:null_or_left isnot l:NULL
      " ^ if the left value is found, return it
      return l:null_or_left  " a left value
    endif

    let l:Func   = s:unsafe_from_right(a:either_func)
    let l:values = map(copy(l:either_values), 'UnsafeFromRightOfEither(v:val)')
    let l:result = s:_get_caller(l:Func)(l:Func, l:values)
    return s:right(l:result)
  finally
    delfunction IsLeftOfEither
    delfunction UnsafeFromRightOfEither
  endtry
endfunction


function! s:join(nested_either) abort
  if s:is_left(a:nested_either)
    return a:nested_either
  endif
  let l:either = s:unsafe_from_right(a:nested_either)

  " Don't return anything if l:either isn't either
  if !s:is_left(l:either) && !s:is_right(l:either)
    throw "vital: Data.Either: join() cannot be applied if the argument isn't nested either"
  endif
  return l:either
endfunction


function! s:bind(either, karrow) abort
  return s:join(s:map(a:either, a:karrow))
endfunction


function! s:flatmap(either, f) abort
	return s:bind(a:either, a:f)
endfunction


function! s:return(x) abort
	return s:right(a:x)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
