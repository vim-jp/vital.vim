let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V)
  let s:V = a:V
  let s:L = s:V.import('Data.List')
endfunction

function! s:_vital_depends()
  return ['Data.List']
endfunction

function! s:_nil() dict
  return [[], {}]
endfunction

function! s:from_list(list)
  return [[], {'list': a:list, 'run': function('s:_f_from_list')}]
endfunction

"return [[], s:L.foldr("[{'value': v:val}, v:memo]", 'nil', a:xs)]
function! s:_f_from_list() dict
  if len(self.list) == 0
    return [[], {}]
  else
    let [x, xs] = [self.list[0], self.list[1 :]]
    return [[x], {'list': xs, 'run': function('s:_f_from_list')}]
  endif
endfunction


function! s:_thunk_eval_from_memo_and_f() dict
  echomsg string(['called', self])
  return []
endfunction

" function! s:iterate(init, f)
"   let thunk = {
"         \ 'memo': a:init, 'f': a:f,
"         \ 'eval': function('s:_thunk_eval_from_memo_and_f')}
"   return [[], {'thunk': thunk}]
" endfunction

function! s:is_empty(xs)
  let [fs, xs] = a:xs
  return s:V.is_string(xs) && xs ==# 'nil'
endfunction

function! s:_eval(fs, x)
  let memo = a:x
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

function! s:_unapply(fs, xs)
  let [x, xs] = a:xs.run()
  return [s:_eval(a:fs, x), xs]
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
    let [x, xs] = s:_unapply(fs, xs)
    if len(x)
      return x + s:take([fs, xs], a:n - 1)
    else
      return s:take([fs, xs], a:n)
    endif
  endif
endfunction

function! s:take_while(xs, f)
  if s:is_empty(a:xs)
    return []
  else
    let [fs, xs] = a:xs
    let [x, xs1] = s:_unapply(xs)
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
"echo s:take(s:iterate(0, 'v:val + 1'), 3)

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
