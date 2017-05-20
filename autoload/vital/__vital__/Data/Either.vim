let s:save_cpo = &cpo
set cpo&vim


function! s:_vital_loaded(V) abort
  let s:List = a:V.import('Data.List')
endfunction

function! s:_vital_depends() abort
  return ['Data.List']
endfunction


" --- private objects --- "

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
  return {'either_left_value': a:x}
endfunction


function! s:right(y) abort
  return {'either_right_value': a:y}
endfunction


function! s:is_left(either) abort
  return type(a:either) is type({}) && has_key(a:either, 'either_left_value')
endfunction


function! s:is_right(either) abort
  return type(a:either) is type({}) && has_key(a:either, 'either_right_value')
endfunction


function! s:is_either(x) abort
  return s:is_left(a:x) || s:is_right(a:x)
endfunction


function! s:unsafe_from_left(either) abort
  if s:is_right(a:either)
    throw 'vital: Data.Either: from_left() cannot be applied by right value'
  endif
  return a:either.either_left_value
endfunction


function! s:unsafe_from_right(either) abort
  if s:is_left(a:either)
    throw 'vital: Data.Either: from_right() cannot be applied by left value'
  endif
  return a:either.either_right_value
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
  let internal  = s:unsafe_from_right(a:either)
  let internal_ = s:_get_caller(a:f)(a:f, [internal])

  return s:right(internal_)
endfunction


function! s:apply(either_func, ...) abort
  if s:is_left(a:either_func)
    return a:either_func
  endif
  let either_values = a:000

  "NOTE: It isn't needed to consider value of other than either. Only either values is considered in here.
  let NULL         = 0 | lockvar NULL
  let null_or_left = s:List.find(either_values, NULL, function('s:is_left'))
  if null_or_left isnot NULL
    " ^ if the left value is found, return it
    return null_or_left  " a left value
  endif

  let l:Func   = s:unsafe_from_right(a:either_func)
  let values = []
  for either_value in either_values
    call add(values, s:unsafe_from_right(either_value))
  endfor
  let l:Call = s:_get_caller(l:Func)
  return s:right(l:Call(l:Func, values))
endfunction


function! s:join(nested_either) abort
  if s:is_left(a:nested_either)
    return a:nested_either
  endif
  let either = s:unsafe_from_right(a:nested_either)

  " Don't return anything if either isn't either
  if !s:is_left(either) && !s:is_right(either)
    throw "vital: Data.Either: join() cannot be applied if the argument isn't nested either"
  endif
  return either
endfunction


function! s:bind(either, karrow) abort
  return s:join(s:map(a:either, a:karrow))
endfunction


function! s:flat_map(either, f) abort
  return s:bind(a:either, a:f)
endfunction


function! s:return(x) abort
  return s:right(a:x)
endfunction


if !exists('v:null')
  function! s:null_to_left(_, __) abort
    throw 'vital: Data.Either: null_to_left() supports only vim8 or later'
  endfunction
else
  function! s:null_to_left(x, error_msg) abort
    return a:x is v:null ? s:left(a:error_msg)
    \                    : s:right(a:x)
  endfunction
endif


let &cpo = s:save_cpo
unlet s:save_cpo
" vim:ts=2:sw=2:et
