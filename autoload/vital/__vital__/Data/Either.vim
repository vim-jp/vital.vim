let s:save_cpo = &cpo
set cpo&vim


" --- private objects --- "

let s:_NOTHING = tempname() | lockvar s:_NOTHING

" Return call of Funcref or String expression
function! s:_get_caller(f) abort
  return type(a:f) is type(function('function'))
  \      ? function('call')
  \      : function('s:_call_string_expr')
endfunction

function! s:_call_string_expr(expr, args)
  return eval(substitute(a:expr, 'v:val', string(a:args[0]), 'g'))
endfunction


" --- public objects --- "

function! s:left(x) abort
  return [a:x, s:_NOTHING]
endfunction


function! s:right(y) abort
  return [s:_NOTHING, a:y]
endfunction


function! s:is_left(either) abort
  let [_, l:may_not_right] = a:either
  return l:may_not_right ==# s:_NOTHING
endfunction


function! s:is_right(either) abort
  return !s:is_left(a:either)
endfunction


function! s:unsafe_from_left(either) abort
  if s:is_right(a:either)
    throw 'vital: Data.Either: from_left() cannot be applied by right value'
  endif
  let [l:x, _] = a:either
  return l:x
endfunction


function! s:unsafe_from_right(either) abort
  if s:is_left(a:either)
    throw 'vital: Data.Either: from_right() cannot be applied by left value'
  endif
  let [_, l:y] = a:either
  return l:y
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
  let l:right = s:unsafe_from_right(a:either)

  return s:_get_caller(a:f)(l:right)
endfunction


function! s:apply(either_func, either_value) abort
  if s:is_left(a:either_func)
    return a:either_func
  elseif s:is_left(a:either_value)
    return a:either_value
  endif
  let l:Func  = s:unsafe_from_right(a:either_func)
  let l:value = s:unsafe_from_right(a:either_value)
  return s:right(l:Func(l:value))
endfunction


function! s:join(either) abort
  if s:is_left(a:either)
    return a:either
  endif
  let l:right = s:unsafe_from_right(a:either)

  " Don't return anything if l:right isn't either
  if !s:is_right(l:right) && !s:is_right(l:right)
    throw "vital: Data.Either: join() cannot be applied if the argument isn't nested either"
  endif
  return l:right
endfunction


function! s:bind(either, karrow) abort
  return s:map(s:map(a:either, a:karrow), s:join)
endfunction


function! s:flatmap(either, f) abort
	return s:bind(a:either, a:f)
endfunction


function! s:return(x) abort
	return s:right(a:x)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
