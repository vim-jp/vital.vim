let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V)
  let s:V = a:V
  let s:L = s:V.import('Data.List')
endfunction

function! s:_vital_depends()
  return ['Data.List']
endfunction

function! s:from_list(xs)
  return [[], s:L.foldr("[{'value': v:val}, v:memo]", 'nil', a:xs)]
endfunction

function! s:is_empty(xs)
  let [fs, xs] = a:xs
  return s:V.is_string(xs) && xs ==# 'nil'
endfunction

function! s:_eval(fs, x)
  if has_key(a:x, 'thunk')
    let x = a:x.thunk()
  elseif has_key(a:x, 'value')
    let x = a:x.value
  else
    throw 'must not happen'
  endif
  let memo = [x]
  for f in a:fs
    if len(memo)
      " f is like 'v:val < 2 ? [v:val] : []'
      let expr = substitute(f, 'v:val', memo[0], 'g')
      unlet memo
      let memo = eval(expr)
    endif
  endfor
  return memo
endfunction

function! s:unapply(xs)
  return [a:xs[0], a:xs[1]]
endfunction

function! s:filter(xs, f)
  let [fs, xs] = a:xs
  let f = printf("%s ? [v:val] : []", a:f)
  return [s:L.conj(fs, f), xs]
endfunction

function! s:take(xs, n)
  if a:n == 0 || s:is_empty(a:xs)
    return []
  else
    let [fs, xs] = a:xs
    let [x, xs1] = s:unapply(xs)
    let ex = s:_eval(fs, x)
    if len(ex)
      return ex + s:take([fs, xs1], a:n - 1)
    else
      return ex + s:take([fs, xs1], a:n)
    endif
  endif
endfunction

function! s:take_while(xs, f)
  if s:is_empty(a:xs)
    return []
  else
    let [fs, xs] = a:xs
    let [x, xs1] = s:unapply(xs)
    let ex = s:_eval(fs, x)
    if len(ex) && eval(substitute(a:f, 'v:val', ex[0], 'g'))
      return ex + s:take_while([fs, xs1], a:f)
    else
      return []
    endif
  endif
endfunction

"let xs = s:L.file_readlines('/tmp/a.txt')
"let xs = s:L.map(xs, 'split(v:val, ":")')
"let xs = s:L.filter(xs, 'v:val[1] < 3')
"echo s:L.take(xs, 3)

" call s:_vital_loaded(g:V)
" echo s:from_list([3, 1, 4])
" echo s:take(s:from_list([3, 1, 4]), 2)
" echo s:take(s:from_list([3, 1, 4]), 2) == [3, 1]
" 
" echo s:take(s:filter(s:from_list([3, 1, 4, 0]), 'v:val < 2'), 2)
" echo s:take_while(s:from_list([3, 1, 4, 1]), 'v:val % 2 == 1')

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
