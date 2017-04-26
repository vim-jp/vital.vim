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

function! s:of(list) abort
  return s:_new_from_list(a:list)
endfunction

function! s:empty() abort
  return s:_new_from_list([])
endfunction

function! s:_new_from_list(list) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = s:_make_characteristics([s:CH_ORDERED, s:CH_SIZED, s:CH_IMMUTABLE])
  let stream._list = a:list
  function! stream.__take__(n)
    return a:n >= 0 ? self._list[: a:n - 1] : self._list[:]
  endfunction
  return stream
endfunction

function! s:_localfunc(name) abort
  return function(s:SNR . a:name)
endfunction

function! s:_SID()
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
endfunction
let s:SNR = '<SNR>' . s:_SID() . '_'

function! s:_illegal_take(...) dict abort
  throw 'vital: Stream: stream has already been operated upon or closed'
endfunction

let s:CH_ORDERED = 0
let s:CH_DISTINCT = 1
let s:CH_SORTED = 2
let s:CH_SIZED = 3
" let s:CH_NONNULL = 4
let s:CH_IMMUTABLE = 5
" let s:CH_CONCURRENT = 6

function! s:_make_characteristics(chlist) abort
  let characteristics = repeat([0], 7)
  for i in a:chlist
    let characteristics[i] = 1
  endfor
  return characteristics
endfunction

function! s:iterate(init, f) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = s:_make_characteristics([s:CH_ORDERED, s:CH_IMMUTABLE])
  let stream.__value = a:init
  let stream._f = a:f
  function! stream.__take__(n)
    let list = []
    for _ in range(max([a:n, 0]))
      let list += [self.__value]
      let self.__value = map([self.__value], self._f)[0]
    endfor
    return list
  endfunction
  return stream
endfunction


let s:Stream = {}

function! s:Stream.map(f) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = self._characteristics
  let stream._upstream = self
  let stream._f = a:f
  function! stream.__take__(n)
    return map(self._upstream.take(a:n), self._f)
  endfunction
  return stream
endfunction

function! s:Stream.limit(n) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = s:_make_characteristics([s:CH_ORDERED, s:CH_SIZED, s:CH_IMMUTABLE])
  let stream._upstream = self
  let stream._n = a:n
  function! stream.__take__(...)
    return self._upstream.take(self._n)
  endfunction
  return stream
endfunction

function! s:Stream.count() abort
  if self._characteristics[s:CH_SIZED]
    return len(self.take(-1))
  endif
  return 1/0
endfunction

function! s:Stream.to_list() abort
  return self.take(-1)
endfunction

function! s:Stream.take(n) dict abort
  let R = self.__take__(a:n)
  let self.take = s:_localfunc('_illegal_take')
  return R
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
