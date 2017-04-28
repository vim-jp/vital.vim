let s:save_cpo = &cpo
set cpo&vim


let s:ORDERED = 0x01
function! s:ORDERED() abort
  return s:ORDERED
endfunction

let s:DISTINCT = 0x02
function! s:DISTINCT() abort
  return s:DISTINCT
endfunction

let s:SORTED = 0x04
function! s:SORTED() abort
  return s:SORTED
endfunction

let s:SIZED = 0x08
function! s:SIZED() abort
  return s:SIZED
endfunction

" let s:NONNULL = 0x10
" function! s:NONNULL() abort
"   return s:NONNULL
" endfunction

let s:IMMUTABLE = 0x20
function! s:IMMUTABLE() abort
  return s:IMMUTABLE
endfunction

" let s:CONCURRENT = 0x40
" function! s:CONCURRENT() abort
"   return s:CONCURRENT
" endfunction

function! s:of(...) abort
  return s:_new_from_list(a:000, s:ORDERED + s:SIZED + s:IMMUTABLE)
endfunction

function! s:from_chars(str, ...) abort
  let characteristics = get(a:000, 0, s:ORDERED + s:SIZED + s:IMMUTABLE)
  return s:_new_from_list(split(a:str, '\zs'), characteristics)
endfunction

function! s:from_list(list, ...) abort
  let characteristics = get(a:000, 0, s:ORDERED + s:SIZED + s:IMMUTABLE)
  return s:_new_from_list(a:list, characteristics)
endfunction

function! s:from_dict(dict, ...) abort
  let characteristics = get(a:000, 0, s:DISTINCT + s:SIZED + s:IMMUTABLE)
  return s:_new_from_list(items(a:dict), characteristics)
endfunction

function! s:empty() abort
  return s:_new_from_list([], s:ORDERED + s:SIZED + s:IMMUTABLE)
endfunction

function! s:_new_from_list(list, characteristics) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = a:characteristics
  let stream.__index = 0
  let stream.__end = 0
  let stream._list = a:list
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed'
    endif
    " max(): fix overflow
    let list = self._list[self.__index : max([self.__index + a:n - 1, a:n - 1])]
    let self.__index = max([self.__index + a:n, a:n])
    let self.__end = (self.__estimate_size__() == 0)
    return [list, !self.__end]
  endfunction
  function! stream.__estimate_size__() abort
    return max([len(self._list) - self.__index, 0])
  endfunction
  return stream
endfunction

function! s:range(start_inclusive, end_exclusive) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics =
  \ s:ORDERED + s:DISTINCT + s:SORTED + s:SIZED + s:IMMUTABLE
  let stream.__index = a:start_inclusive
  let stream._end_exclusive = a:end_exclusive
  let stream.__end = 0
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed'
    endif
    " take n, but do not exceed end. and range(1,-1) causes E727 error.
    " max(): fix overflow
    let take_n = max([self.__index + a:n - 1, a:n - 1])
    let end_exclusive = self._end_exclusive - 1
    let e727_fix = self.__index - 1
    let end = max([min([take_n, end_exclusive]), e727_fix])
    let list = range(self.__index, end)
    let self.__index = end + 1
    let self.__end = self.__estimate_size__() == 0
    return [list, !self.__end]
  endfunction
  function! stream.__estimate_size__() abort
    return max([self._end_exclusive - self.__index, 0])
  endfunction
  return stream
endfunction

function! s:range_closed(start_inclusive, end_inclusive) abort
  return s:range(a:start_inclusive, a:end_inclusive + 1)
endfunction

function! s:iterate(init, f) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = s:ORDERED + s:IMMUTABLE
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

function! s:_localfunc(name) abort
  return function(s:SNR . a:name)
endfunction

function! s:_SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
endfunction
let s:SNR = '<SNR>' . s:_SID() . '_'


let s:Stream = {}

function! s:Stream.has_characteristic(flag) abort
  return !!and(self._characteristics, a:flag)
endfunction

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
    let self.__end = (self.__estimate_size__() == 0)
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
  let stream._characteristics = s:ORDERED + s:SIZED + s:IMMUTABLE
  let stream._upstream = self
  let stream.__end = 0
  let stream._n = max([a:n, 0])
  function! stream.__take_possible__(...) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed'
    endif
    let list = self._n > 0 ? self._upstream.__take_possible__(self._n)[0] : []
    let self.__end = (self.__estimate_size__() == 0)
    return [list, !self.__end]
  endfunction
  function! stream.__estimate_size__() abort
    return min([self._n, self._upstream.__estimate_size__()])
  endfunction
  return stream
endfunction

function! s:Stream.count() abort
  if self.has_characteristic(s:SIZED)
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
