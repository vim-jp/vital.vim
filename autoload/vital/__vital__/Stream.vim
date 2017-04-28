let s:save_cpo = &cpo
set cpo&vim

function! s:of(...) abort
  return s:_new_from_list(a:000)
endfunction

function! s:empty() abort
  return s:_new_from_list([])
endfunction

function! s:_new_from_list(list) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = s:_make_characteristics([s:CH_ORDERED, s:CH_SIZED, s:CH_IMMUTABLE])
  let stream.__index = 0
  let stream.__end = 0
  let stream._list = a:list
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed'
    endif
    let list = self._list[self.__index : self.__index + a:n - 1]
    let self.__index += a:n
    let self.__end = (self.__estimate_size__() == 0)
    return [list, !self.__end]
  endfunction
  function! stream.__estimate_size__() abort
    return max([len(self._list) - self.__index, 0])
  endfunction
  return stream
endfunction

function! s:_localfunc(name) abort
  return function(s:SNR . a:name)
endfunction

function! s:_SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
endfunction
let s:SNR = '<SNR>' . s:_SID() . '_'

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
  function! stream.__take_possible__(n) abort
    let list = []
    let i = 0
    while i < a:n
      let list += [self.__value]
      let self.__value = map([self.__value], self._f)[0]
      let i += 1
    endwhile
    return [list, 1]
  endfunction
  function! stream.__estimate_size__() abort
    return 1/0
  endfunction
  return stream
endfunction


let s:Stream = {}

function! s:Stream.map(f) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = self._characteristics
  let stream._upstream = self
  let stream.__end = 0
  let stream._f = a:f
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed'
    endif
    let list = map(self._upstream.__take_possible__(a:n)[0], self._f)
    let self.__end = (self._upstream.__estimate_size__() == 0)
    return [list, !self.__end]
  endfunction
  function! stream.__estimate_size__() abort
    return self._upstream.__estimate_size__()
  endfunction
  return stream
endfunction

function! s:Stream.filter(f) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = self._characteristics
  let stream._upstream = self
  let stream.__end = 0
  let stream._f = a:f
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed'
    endif
    let [r, open] = self._upstream.__take_possible__(a:n)
    let list = filter(r, self._f)
    while open && len(list) < a:n
      let [r, open] = self._upstream.__take_possible__(a:n - len(list))
      let list += filter(r, self._f)
    endwhile
    if !open
      let self.__end = 1
    endif
    return [list, open]
  endfunction
  function! stream.__estimate_size__() abort
    return self._upstream.__estimate_size__()
  endfunction
  return stream
endfunction

function! s:Stream.limit(n) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = s:_make_characteristics([s:CH_ORDERED, s:CH_SIZED, s:CH_IMMUTABLE])
  let stream._upstream = self
  let stream.__end = 0
  let stream._n = a:n
  function! stream.__take_possible__(...) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed'
    endif
    let list = self._upstream.__take_possible__(self._n)[0]
    let self.__end = (self._upstream.__estimate_size__() == 0)
    return [list, !self.__end]
  endfunction
  function! stream.__estimate_size__() abort
    return min([self._n, self._upstream.__estimate_size__()])
  endfunction
  return stream
endfunction

function! s:Stream.count() abort
  if self._characteristics[s:CH_SIZED]
    return len(self.__take_possible__(self.__estimate_size__())[0])
  endif
  return 1/0
endfunction

function! s:Stream.to_list() abort
  return self.__take_possible__(self.__estimate_size__())[0]
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
