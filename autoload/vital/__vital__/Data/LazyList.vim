let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:L = s:V.import('Data.List')
  let s:P = s:V.import('Process')
endfunction

function! s:_vital_depends() abort
  return ['Data.List', 'Process']
endfunction

function! s:from_list(list) abort
  return [[], {'list': a:list, 'run': function('s:_f_from_list')}]
endfunction

function! s:_f_from_list() dict abort
  if len(self.list) == 0
    return [[], {}]
  else
    let [x, xs] = [self.list[0], self.list[1 :]]
    return [[x], {'list': xs, 'run': function('s:_f_from_list')}]
  endif
endfunction

function! s:file_readlines(fname) abort
  if !s:P.has_vimproc()
    throw 'vital: Data.LazyList: file_readlines() requires vimproc'
  endif
  return [[], {
        \ 'f': vimproc#fopen(a:fname, 'r'),
        \ 'run': function('s:_f_file_readlines')}]
endfunction

" TODO resource management
function! s:_f_file_readlines() dict abort
  if self.f.eof
    call self.f.close()
    return [[], {}]
  else
    " caution: this is destructive!
    return [[self.f.read_line()], self]
  endif
endfunction

function! s:iterate(init, f) abort
  let thunk = {
        \ 'memo': a:init, 'f': a:f,
        \ 'run': function('s:_f_iterate')}
  return [[], thunk]
endfunction

function! s:_f_iterate() dict abort
  let next_thunk = {
        \ 'memo': eval(substitute(self.f, 'v:val', self.memo, 'g')),
        \ 'f': self.f,
        \ 'run': self.run}
  return [[self.memo], next_thunk]
endfunction

function! s:zip(xs, ys) abort
  let [xfs, xs] = a:xs
  let [yfs, ys] = a:ys
  let thunk = {
        \ 'xfs': xfs, 'yfs': yfs,
        \ 'xs': xs, 'ys': ys,
        \ 'run': function('s:_f_zip')}
  return [[], thunk]
endfunction

function! s:_f_zip() dict abort
  let [x, xs] = s:_unapply(self.xfs, self.xs)
  let [y, ys] = s:_unapply(self.yfs, self.ys)
  if len(x) == 0 || len(y) == 0
    return [[], {}]
  else
    let next_thunk = {
          \ 'xfs': self.xfs, 'yfs': self.yfs,
          \ 'xs': xs, 'ys': ys,
          \ 'run': self.run}
    return [[[x[0], y[0]]], next_thunk]
  endif
endfunction

function! s:is_empty(xs) abort
  return a:xs[1] == {}
endfunction

function! s:_eval(fs, x) abort
  let memo = a:x
  for f in a:fs
    if len(memo)
      " f is like 'v:val < 2 ? [v:val] : []'
      let expr = substitute(f, 'v:val', string(memo[0]), 'g')
      unlet memo
      let memo = eval(expr)
    endif
  endfor
  return memo
endfunction

function! s:_unapply(fs, xs) abort
  let [x, xs] = a:xs.run()
  return [s:_eval(a:fs, x), xs]
endfunction

function! s:filter(xs, f) abort
  let [fs, xs] = a:xs
  let f = printf('%s ? [v:val] : []', a:f)
  return [s:L.conj(fs, f), xs]
endfunction

function! s:map(xs, f) abort
  let [fs, xs] = a:xs
  let f = printf('[%s]', a:f)
  return [s:L.conj(fs, f), xs]
endfunction

function! s:take(n, xs) abort
  if a:n == 0 || s:is_empty(a:xs)
    return []
  else
    let [fs, xs] = a:xs
    let [x, xs] = s:_unapply(fs, xs)
    if len(x)
      return x + s:take(a:n - 1, [fs, xs])
    else
      return s:take(a:n, [fs, xs])
    endif
  endif
endfunction

function! s:take_while(xs, f) abort
  if s:is_empty(a:xs)
    return []
  else
    let [fs, xs] = a:xs
    let [x, xs1] = s:_unapply(fs, xs)
    if len(x) && eval(substitute(a:f, 'v:val', x[0], 'g'))
      return x + s:take_while([fs, xs1], a:f)
    else
      return []
    endif
  endif
endfunction

function! s:first(xs, default) abort
  let xs = s:take(1, a:xs)
  return len(xs) == 0 ? a:default : xs[0]
endfunction

function! s:rest(xs, default) abort
  if s:is_empty(a:xs)
    return a:default
  else
    let [fs, xs] = a:xs
    let xs = s:_unapply(fs, xs)[1]
    return [fs, xs]
  endif
endfunction

function! s:drop(n, xs) abort
  if s:is_empty(a:xs)
    return []
  else
    let xs = a:xs[1]
    let memo = xs.memo
    for _ in range(1,a:n)
      let memo = s:_eval([ xs.f ], memo)
    endfor
    let new_xs = deepcopy(a:xs)
    let new_xs[1].memo = memo
    return new_xs
  endif
endfunction


" echo s:L.take(10,         s:L.iterate(0, 'v:val + 1') )
" [    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, ]
" echo s:L.take(10,s:drop(3,s:L.iterate(0, 'v:val + 1')))
" [    3, 4, 5, 6, 7, 8, 9, 10, 11, 12, ]


 
"call s:_vital_loaded(g:V)
"let xs = s:file_readlines('/tmp/a.txt')
"let xs = s:map(xs, 'split(v:val, ":")')
"let xs = s:filter(xs, 'v:val[1] < 3')
"echo s:take(3, xs)

" echo s:from_list([3, 1, 4])
"let xs = s:from_list([3, 1, 4])
"let ys = s:from_list(['a', 'b', 'c'])
"echo s:take(3, s:zip(s:map(xs, 'v:val + 1'), ys))
" echo s:take(2, s:from_list([3, 1, 4]))
" echo s:take(2, s:from_list([3, 1, 4])) == [3, 1]
" 
" echo s:take(2, s:filter(s:from_list([3, 1, 4, 0]), 'v:val < 2'))
" echo s:take_while(s:from_list([3, 1, 4, 1]), 'v:val % 2 == 1')
" echo s:take(3, s:iterate(0, 'v:val + 1'))
" echo s:take(3, s:filter(s:iterate(0, 'v:val + 1'), 'v:val % 2 == 0'))
" echo s:take(4, s:file_readlines('/tmp/a.txt'))
" echo s:take(3, s:map(s:iterate(0, 'v:val + 1'), 'v:val * 2'))
" echo s:first(s:from_list([3, 1, 4]), 'nil')
" echo s:first(s:filter(s:from_list([3, 1, 4]), '0'), 'nil')
" echo s:rest(s:from_list([3, 1, 4]), s:from_list([]))
" echo s:first(s:rest(s:from_list([3, 1, 4]), s:from_list([])), 'nil')

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
