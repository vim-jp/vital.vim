let s:save_cpo = &cpo
set cpo&vim


let s:t_number = 0
let s:t_string = 1
let s:t_func = 2
let s:t_list = 3
let s:t_dict = 4
let s:t_float = 5
let s:t_bool = 6
let s:t_none = 7
let s:t_job = 8
let s:t_channel = 9

let s:ORDERED = 0x01
let s:DISTINCT = 0x02
let s:SORTED = 0x04
let s:SIZED = 0x08
" let s:NONNULL = 0x10
let s:IMMUTABLE = 0x20
" let s:CONCURRENT = 0x40

function! s:ORDERED() abort
  return s:ORDERED
endfunction

function! s:DISTINCT() abort
  return s:DISTINCT
endfunction

function! s:SORTED() abort
  return s:SORTED
endfunction

function! s:SIZED() abort
  return s:SIZED
endfunction

" function! s:NONNULL() abort
"   return s:NONNULL
" endfunction

function! s:IMMUTABLE() abort
  return s:IMMUTABLE
endfunction

" function! s:CONCURRENT() abort
"   return s:CONCURRENT
" endfunction

function! s:of(...) abort
  return s:_new_from_list(a:000, s:ORDERED + s:SIZED + s:IMMUTABLE, 'of()')
endfunction

function! s:from_chars(str, ...) abort
  let characteristics = get(a:000, 0, s:ORDERED + s:SIZED + s:IMMUTABLE)
  return s:_new_from_list(split(a:str, '\zs'), characteristics, 'from_chars()')
endfunction

function! s:from_list(list, ...) abort
  let characteristics = get(a:000, 0, s:ORDERED + s:SIZED + s:IMMUTABLE)
  return s:_new_from_list(a:list, characteristics, 'from_list()')
endfunction

function! s:from_dict(dict, ...) abort
  let characteristics = get(a:000, 0, s:DISTINCT + s:SIZED + s:IMMUTABLE)
  return s:_new_from_list(items(a:dict), characteristics, 'from_dict()')
endfunction

function! s:empty() abort
  return s:_new_from_list([], s:ORDERED + s:SIZED + s:IMMUTABLE, 'empty()')
endfunction

function! s:_new_from_list(list, characteristics, callee) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = a:characteristics
  let stream.__index = 0
  let stream.__end = 0
  let stream._list = a:list
  let stream._callee = a:callee
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at '
      \     . self._callee
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
      throw 'vital: Stream: stream has already been operated upon or closed at range()'
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

function! s:generate(f) abort
  let type = type(a:f)
  return s:iterate(
  \ type is s:t_func ? a:f() :
  \ type is s:t_string ? eval(a:f) : 0,
  \ a:f)
endfunction

function! s:zip(s1, s2) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = and(a:s1._characteristics, a:s2._characteristics)
  let stream.__end = 0
  let stream._s1 = a:s1
  let stream._s2 = a:s2
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at zip()'
    endif
    let l1 = self._s1.__take_possible__(a:n)[0]
    let l2 = self._s2.__take_possible__(a:n)[0]
    let smaller = min([len(l1), len(l2)])
    let list = map(range(smaller), '[l1[v:val], l2[v:val]]')
    let self.__end = (self.__estimate_size__() == 0)
    return [list, !self.__end]
  endfunction
  function! stream.__estimate_size__() abort
    return min([self._s1.__estimate_size__(), self._s2.__estimate_size__()])
  endfunction
  return stream
endfunction

function! s:concat(s1, s2) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = and(a:s1._characteristics, a:s2._characteristics)
  let stream.__end = 0
  let stream._s1 = a:s1
  let stream._s2 = a:s2
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at concat()'
    endif
    let list = []
    if self._s1.__estimate_size__() > 0
      let list += self._s1.__take_possible__(a:n)[0]
    endif
    if len(list) < a:n && self._s2.__estimate_size__() > 0
      let list += self._s2.__take_possible__(a:n - len(list))[0]
    endif
    let self.__end = (self._s1.__estimate_size__() == 0 &&
    \                 self._s2.__estimate_size__() == 0)
    return [list, !self.__end]
  endfunction
  function! stream.__estimate_size__() abort
    let size1 = self._s1.__estimate_size__()
    let size2 = self._s2.__estimate_size__()
    return size1 + size2 >= size1 ? size1 + size2 : 1/0
  endfunction
  return stream
endfunction


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
      throw 'vital: Stream: stream has already been operated upon or closed at map()'
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
      throw 'vital: Stream: stream has already been operated upon or closed at filter()'
    endif
    let [r, open] = self._upstream.__take_possible__(a:n)
    let list = filter(r, self._f)
    while open && len(list) < a:n
      let [r, open] = self._upstream.__take_possible__(a:n - len(list))
      let list += filter(r, self._f)
    endwhile
    let self.__end = !open
    return [list, open]
  endfunction
  function! stream.__estimate_size__() abort
    return self._upstream.__estimate_size__()
  endfunction
  return stream
endfunction

" 'n' may be 1/0, so when upstream is inifinite stream,
" 'self._upstream.__take_possible__(n)' does not stop
" unless .limit(n) was specified in downstream.
" But regardless of whether .limit(n) was specified,
" this method must stop for even upstream is inifinite stream.
function! s:Stream.take_while(f) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = self._characteristics
  let stream._upstream = self
  let stream.__end = 0
  let stream._f = a:f
  let stream._BUFSIZE = 32
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at take_while()'
    endif
    let do_break = 0
    let list = []
    while !do_break
      let [r, open] = self._upstream.__take_possible__(self._BUFSIZE)
      for Value in (a:n > 0 ? r : [])
        if !map([Value], self._f)[0]
          let open = 0
          let do_break = 1
          break
        endif
        let list += [Value]
        if len(list) >= a:n
          " requested number of elements was obtained,
          " but this stream is not closed for next call
          let do_break = 1
          break
        endif
      endfor
      if !open
        break
      endif
    endwhile
    let self.__end = !open
    return [list, open]
  endfunction
  if self.has_characteristic(s:SIZED)
    function! stream.__estimate_size__() abort
      return self._upstream.__estimate_size__()
    endfunction
  else
    function! stream.__estimate_size__() abort
      return 1/0
    endfunction
  endif
  return stream
endfunction

function! s:Stream.drop_while(f) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = self._characteristics
  let stream._upstream = self
  let stream.__end = 0
  let stream.__skipping = 1
  let stream._f = a:f
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at take_while()'
    endif
    let list = []
    let open = self.__estimate_size__()
    while self.__skipping && open
      let [r, open] = self._upstream.__take_possible__(a:n)
      for i in range(len(r))
        if !map([r[i]], self._f)[0]
          let self.__skipping = 0
          let list = r[i :]
          break
        endif
      endfor
    endwhile
    if !self.__skipping && open && len(list) < a:n
      let [r, open] = self._upstream.__take_possible__(a:n - len(list))
      let list += r
    endif
    let self.__end = !open
    return [list, open]
  endfunction
  if self.has_characteristic(s:SIZED)
    function! stream.__estimate_size__() abort
      return self._upstream.__estimate_size__()
    endfunction
  else
    function! stream.__estimate_size__() abort
      return 1/0
    endfunction
  endif
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
      throw 'vital: Stream: stream has already been operated upon or closed at limit()'
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

function! s:Stream.zip(stream) abort
  return s:zip(self, a:stream)
endfunction

function! s:Stream.concat(stream) abort
  return s:concat(self, a:stream)
endfunction

function! s:Stream.reduce(f, ...) abort
  let Result = get(a:000, 0, 0)
  let type = type(a:f)
  if type is s:t_string
    for Value in self.__take_possible__(self.__estimate_size__())[0]
      let Result = map([[Result, Value]], a:f)[0]
    endfor
  elseif type is s:t_func
    for Value in self.__take_possible__(self.__estimate_size__())[0]
      let Result = a:f(Result, Value)
    endfor
  else
    throw 'vital: Stream: reduce(): invalid type argument was given (Funcref or String or Data.Closure)'
  endif
  return Result
endfunction

function! s:Stream.max(...) abort
  if self.__estimate_size__() == 0
    return get(a:000, 0, 0)
  endif
  return max(self.__take_possible__(self.__estimate_size__())[0])
endfunction

function! s:Stream.max_by(f, ...) abort
  if self.__estimate_size__() == 0
    return get(a:000, 0, 0)
  endif
  let [first] = self.__take_possible__(1)[0]
  let type = type(a:f)
  if type is s:t_string
    return self.reduce('max([map([v:val[1]], a:f)[0], v:val[0]])', map([first], a:f)[0])
  elseif type is s:t_func
    return self.reduce('max([a:f(v:val[1]), v:val[0]])', a:f(first))
  else
    throw 'vital: Stream: max_by(): invalid type argument was given (Funcref or String or Data.Closure)'
  endif
endfunction

function! s:Stream.min(...) abort
  if self.__estimate_size__() == 0
    return get(a:000, 0, 0)
  endif
  return min(self.__take_possible__(self.__estimate_size__())[0])
endfunction

function! s:Stream.min_by(f, ...) abort
  if self.__estimate_size__() == 0
    return get(a:000, 0, 0)
  endif
  let [first] = self.__take_possible__(1)[0]
  let type = type(a:f)
  if type is s:t_string
    return self.reduce('min([map([v:val[1]], a:f)[0], v:val[0]])', map([first], a:f)[0])
  elseif type is s:t_func
    return self.reduce('min([a:f(v:val[1]), v:val[0]])', a:f(first))
  else
    throw 'vital: Stream: min_by(): invalid type argument was given (Funcref or String or Data.Closure)'
  endif
endfunction

function! s:Stream.find_first(...) abort
  let Default = get(a:000, 0, 0)
  if self.__estimate_size__() == 0
    return Default
  endif
  return get(self.__take_possible__(1)[0], 0, Default)
endfunction

function! s:Stream.find(f, ...) abort
  if self.__estimate_size__() == 0
    return get(a:000, 0, 0)
  endif
  return self.filter(a:f).limit(1).find_first()
endfunction

function! s:Stream.any_match(f) abort
  let type = type(a:f)
  if type is s:t_string
    let NONE = []
    return self.filter(a:f).find_first(NONE) isnot NONE
  elseif type is s:t_func
    throw 'vital: Stream: any_match(): does not support Funcref yet'
  else
    throw 'vital: Stream: any_match(): invalid type argument was given (Funcref or String or Data.Closure)'
  endif
endfunction

function! s:Stream.all_match(f) abort
  let type = type(a:f)
  if type is s:t_string
    let NONE = []
    return self.filter('!map([v:val], '.string(a:f).')[0]').find_first(NONE) is NONE
  elseif type is s:t_func
    throw 'vital: Stream: all_match(): does not support Funcref yet'
  else
    throw 'vital: Stream: all_match(): invalid type argument was given (Funcref or String or Data.Closure)'
  endif
endfunction

function! s:Stream.none_match(f) abort
  let type = type(a:f)
  if type is s:t_string
    let NONE = []
    return self.filter(a:f).find_first(NONE) is NONE
  elseif type is s:t_func
    throw 'vital: Stream: none_match(): does not support Funcref yet'
  else
    throw 'vital: Stream: none_match(): invalid type argument was given (Funcref or String or Data.Closure)'
  endif
endfunction

function! s:Stream.sum() abort
  if !self.has_characteristic(s:SIZED)
    throw 'vital: Stream: sum(): inifinite stream cannot be summed'
  endif
  return self.reduce('v:val[0] + v:val[1]', 0)
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
