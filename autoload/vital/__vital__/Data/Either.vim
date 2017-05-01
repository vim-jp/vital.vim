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
  try
    let l:result = has_key(a:either, 'either_left_value')
    return l:result
  catch /^Vim\%((\a\+)\)\=:E715/
    return 0
  endtry
endfunction


function! s:is_right(either) abort
  try
    return has_key(a:either, 'either_right_value')
  catch /^Vim\%((\a\+)\)\=:E715/
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
  try
    let l:NULL         = 0 | lockvar l:NULL
    let l:null_or_left = s:List.find(l:either_values, l:NULL, 'IsLeftOfEither(v:val)')
    if l:null_or_left isnot l:NULL
      " ^ if the left value is found, return it
      return l:null_or_left  " a left value
    endif

    let l:Func   = s:unsafe_from_right(a:either_func)
    let l:values = []
    for l:either_value in l:either_values
      call add(l:values, s:unsafe_from_right(l:either_value))
    endfor
    let l:result = s:_get_caller(l:Func)(l:Func, l:values)
    return s:right(l:result)
  finally
    delfunction IsLeftOfEither
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
" vim:ts=2:sw=2:et
