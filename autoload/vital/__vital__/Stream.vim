let s:save_cpo = &cpo
set cpo&vim

" ============= Design of Internal API =============
"
" * __take_possible__(n)
"   * n must be 0 or positive
"     * callee must not pass negative value
"     * in order to take all elements from the stream, pass 1/0
"   * this function returns '[list, open]'
"     * 'len(list) <= n'
"     * callee must not invoke this function after 'open == 0' is returned
" * `__estimate_size__()`
"   * this function must not change stream's state
"   * if the number of elements is 'unknown', 1/0 is returned
"     * 'flatmap()' cannot determine the number of elements of the result
"     * 'Stream.of(0,1,2,3).flatmap({n -> repeat([n], n)}).to_list() == [1,2,2,3,3,3]'
"     * 'Stream.of(0,1,2,3).flatmap({n -> repeat([n], n)}).__estimate_size__() == 1/0'
"   * if the stream is finite stream ('stream.has_characteristics(s:SIZED) == 1'),
"     returns the number of rest elements
"   * if the stream is infinite stream ('stream.has_characteristics(s:SIZED) == 0'),
"     returns 1/0
"

function! s:_vital_loaded(V) abort
  let s:Closure = a:V.import('Data.Closure')
endfunction

function! s:_vital_depends() abort
  return ['Data.Closure']
endfunction

let s:NONE = []
lockvar! s:NONE

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

function! s:chars(str, ...) abort
  let characteristics = get(a:000, 0, s:ORDERED + s:SIZED + s:IMMUTABLE)
  return s:_new_from_list(split(a:str, '\zs'), characteristics, 'chars()')
endfunction

function! s:lines(str, ...) abort
  let characteristics = get(a:000, 0, s:ORDERED + s:SIZED + s:IMMUTABLE)
  let lines = a:str ==# '' ? [] : split(a:str, '\n', 1)
  return s:_new_from_list(lines, characteristics, 'lines()')
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
    let n = max([self.__index + a:n - 1, a:n - 1])
    " min(): https://github.com/vim-jp/issues/issues/1049
    let list = self._list[self.__index : min([n, len(self._list) - 1])]
    let self.__index = max([self.__index + a:n, a:n])
    let self.__end = (self.__estimate_size__() ==# 0)
    return [list, !self.__end]
  endfunction
  function! stream.__estimate_size__() abort
    return max([len(self._list) - self.__index, 0])
  endfunction
  return stream
endfunction

function! s:range(start_inclusive, end_inclusive) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics =
  \ s:ORDERED + s:DISTINCT + s:SORTED + s:SIZED + s:IMMUTABLE
  let stream.__index = a:start_inclusive
  let stream._end_exclusive = a:end_inclusive + 1
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
    let self.__end = self.__estimate_size__() ==# 0
    return [list, !self.__end]
  endfunction
  function! stream.__estimate_size__() abort
    return max([self._end_exclusive - self.__index, 0])
  endfunction
  return stream
endfunction

function! s:iterate(init, f) abort
  let l:Call = s:_get_callfunc_for_func1(a:f, 'iterate()')
  return s:_inf_stream(a:f, a:init, l:Call, 'self._call(self._f, [v:val])')
endfunction

function! s:generate(f) abort
  let l:Call = s:_get_callfunc_for_func0(a:f, 'generate()')
  return s:_inf_stream(a:f, l:Call(a:f, []), l:Call, 'self._call(self._f, [])')
endfunction

function! s:_inf_stream(f, init, call, expr) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = s:ORDERED + s:IMMUTABLE
  let stream._f = a:f
  let stream.__value = a:init
  let stream._call = a:call
  let stream._expr = a:expr
  function! stream.__take_possible__(n) abort
    let list = []
    let i = 0
    while i < a:n
      let list += [self.__value]
      let self.__value = map([self.__value], self._expr)[0]
      let i += 1
    endwhile
    return [list, 1]
  endfunction
  function! stream.__estimate_size__() abort
    return 1/0
  endfunction
  return stream
endfunction

function! s:generator(dict) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = 0
  let stream._dict = a:dict
  let stream.__end = 0
  let stream.__index = 0
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at generator()'
    endif
    let list = []
    let i = 0
    let open = 1
    while i < a:n
      let l:Value = self._dict.yield(i + self.__index, s:NONE)
      if l:Value is s:NONE
        let open = 0
        break
      endif
      let list += [l:Value]
      let i += 1
      unlet l:Value
    endwhile
    let self.__index += i
    let self.__end = !open
    return [list, open]
  endfunction
  function! stream.__estimate_size__() abort
    return 1/0
  endfunction
  return stream
endfunction

function! s:zip(s1, s2, ...) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics =
  \ s:_zip_characteristics(map([a:s1, a:s2] + a:000, 'v:val._characteristics'))
  let stream.__end = 0
  let stream._streams = [a:s1, a:s2] + a:000
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at zip()'
    endif
    let lists = map(copy(self._streams), 'v:val.__take_possible__(a:n)[0]')
    let smaller = min(map(copy(lists), 'len(v:val)'))
    " lists = [[1,2,3], [4,5,6]], list = [[1,4], [2,5], [3,6]]
    " let list = map(range(smaller), '[lists[0][v:val], lists[1][v:val], ...]')
    let expr = '['.join(map(range(len(lists)), '''lists[''.v:val.''][v:val]'''), ',').']'
    let list = map(range(smaller), expr)
    let self.__end = (self.__estimate_size__() ==# 0)
    return [list, !self.__end]
  endfunction
  function! stream.__estimate_size__() abort
    return min(map(copy(self._streams), 'v:val.__estimate_size__()'))
  endfunction
  return stream
endfunction

" Use or() for SIZED flag. Use and() for other flags
function! s:_zip_characteristics(characteristics_list) abort
  if len(a:characteristics_list) <= 1
    return a:characteristics_list[0]
  endif
  let [c1, c2; others] = a:characteristics_list
  let result = or(and(c1, c2), and(or(c1, c2), s:SIZED))
  return s:_zip_characteristics([result] + others)
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
    let self.__end = (self._s1.__estimate_size__() ==# 0 &&
    \                 self._s2.__estimate_size__() ==# 0)
    return [list, !self.__end]
  endfunction
  if stream._s1.has_characteristics(s:SIZED) && stream._s2.has_characteristics(s:SIZED)
    " 1/0 when overflow
    function! stream.__estimate_size__() abort
      let size1 = self._s1.__estimate_size__()
      let size2 = self._s2.__estimate_size__()
      return size1 + size2 >= size1 ? size1 + size2 : 1/0
    endfunction
  else
    function! stream.__estimate_size__() abort
      return 1/0
    endfunction
  endif
  return stream
endfunction


let s:Stream = {}

function! s:Stream.has_characteristics(flags) abort
  let flags = type(a:flags) isnot s:t_list ? [a:flags] : a:flags
  if empty(flags)
    return 0
  endif
  let c = flags[0]
  for flag in flags[1:]
    let c = or(c, flag)
  endfor
  return !!and(self._characteristics, c)
endfunction

function! s:Stream.peek(f) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = self._characteristics
  let stream._upstream = self
  let stream.__end = 0
  let stream._call = s:_get_callfunc_for_func1(a:f, 'peek()')
  let stream._f = a:f
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at peek()'
    endif
    let list = self._upstream.__take_possible__(a:n)[0]
    call map(copy(list), 'self._call(self._f, [v:val])')
    let self.__end = (self.__estimate_size__() ==# 0)
    return [list, !self.__end]
  endfunction
  function! stream.__estimate_size__() abort
    return self._upstream.__estimate_size__()
  endfunction
  return stream
endfunction

function! s:Stream.map(f) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = self._characteristics
  let stream._upstream = self
  let stream.__end = 0
  let stream._call = s:_get_callfunc_for_func1(a:f, 'map()')
  let stream._f = a:f
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at map()'
    endif
    let list = self._upstream.__take_possible__(a:n)[0]
    call map(list, 'self._call(self._f, [v:val])')
    let self.__end = (self.__estimate_size__() ==# 0)
    return [list, !self.__end]
  endfunction
  function! stream.__estimate_size__() abort
    return self._upstream.__estimate_size__()
  endfunction
  return stream
endfunction

function! s:Stream.flatmap(f) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = self._characteristics
  let stream._upstream = self
  let stream.__end = 0
  let stream._call = s:_get_callfunc_for_func1(a:f, 'flatmap()')
  let stream._f = a:f
  if self.has_characteristics(s:SIZED)
    function! stream.__take_possible__(n) abort
      if self.__end
        throw 'vital: Stream: stream has already been operated upon or closed at flatmap()'
      endif
      let list = []
      for l in map(
      \       self._upstream.__take_possible__(1/0)[0],
      \       'self._call(self._f, [v:val])')
        if len(l) + len(list) < a:n
          let list += l
        else
          " min(): https://github.com/vim-jp/issues/issues/1049
          let list += l[: min([a:n - len(list), len(l)]) - 1]
          break
        endif
      endfor
      let self.__end = len(list) >= a:n || (self.__estimate_size__() ==# 0)
      return [list, !self.__end]
    endfunction
  else
    let stream.__buffer = []
    function! stream.__take_possible__(n) abort
      if self.__end
        throw 'vital: Stream: stream has already been operated upon or closed at filter()'
      endif
      let list = []
      while len(list) < a:n
        if len(self.__buffer) < a:n
          let self.__buffer += self._upstream.__take_possible__(a:n)[0]
        endif
        " min(): https://github.com/vim-jp/issues/issues/1049
        let end_index = min([a:n, len(self.__buffer)]) - 1
        let r = self.__buffer[: end_index]
        let self.__buffer = self.__buffer[end_index + 1 :]
        " add results to list. len(l) <= a:n when the loop is end
        for l in map(r, 'self._call(self._f, [v:val])')
          if len(l) + len(list) < a:n
            let list += l
          else
            " min(): https://github.com/vim-jp/issues/issues/1049
            let end_index = min([a:n - len(list), len(l)]) - 1
            let list += l[: end_index]
            let self.__buffer = l[end_index + 1 :] + self.__buffer
            break
          endif
        endfor
      endwhile
      let self.__end = len(list) >= a:n || (self.__estimate_size__() ==# 0)
      return [list, !self.__end]
    endfunction
  endif
  " the number of elements in stream is unknown (decreased, as-is, or increased)
  function! stream.__estimate_size__() abort
    return 1/0
  endfunction
  return stream
endfunction

function! s:Stream.filter(f) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = self._characteristics
  let stream._upstream = self
  let stream.__end = 0
  let stream._call = s:_get_callfunc_for_func1(a:f, 'filter()')
  let stream._f = a:f
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at filter()'
    endif
    let [r, open] = self._upstream.__take_possible__(a:n)
    let list = filter(r, 'self._call(self._f, [v:val])')
    while open && len(list) < a:n
      let [r, open] = self._upstream.__take_possible__(a:n - len(list))
      let list += filter(r, 'self._call(self._f, [v:val])')
    endwhile
    let self.__end = !open
    return [list, open]
  endfunction
  function! stream.__estimate_size__() abort
    return self._upstream.__estimate_size__()
  endfunction
  return stream
endfunction

" __take_possible__(n): n may be 1/0, so when upstream is infinite stream,
" 'self._upstream.__take_possible__(n)' does not stop
" unless .limit(n) was specified in downstream.
" But regardless of whether .limit(n) was specified,
" this method must stop for even upstream is infinite stream
" if 'a:f' is not matched at any element in the stream.
function! s:Stream.take_while(f) abort
  let stream = deepcopy(s:Stream)
  let stream._characteristics = self._characteristics
  let stream._upstream = self
  let stream.__end = 0
  let stream._call = s:_get_callfunc_for_func1(a:f, 'take_while()')
  let stream._f = a:f
  let stream._BULK_SIZE = 32
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at take_while()'
    endif
    let open = (self._upstream.__estimate_size__() > 0)
    if a:n ==# 0
      return [[], open]
    endif
    let do_break = 0
    let list = []
    while !do_break
      let [r, open] = self._upstream.__take_possible__(self._BULK_SIZE)
      for l:Value in r
        if !map([l:Value], 'self._call(self._f, [v:val])')[0]
          let open = 0
          let do_break = 1
          break
        endif
        let list += [l:Value]
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
  if self.has_characteristics(s:SIZED)
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
  let stream._call = s:_get_callfunc_for_func1(a:f, 'drop_while()')
  let stream._f = a:f
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at take_while()'
    endif
    let list = []
    let open = (self.__estimate_size__() > 0)
    while self.__skipping && open
      let [r, open] = self._upstream.__take_possible__(a:n)
      for i in range(len(r))
        if !map([r[i]], 'self._call(self._f, [v:val])')[0]
          let self.__skipping = 0
          " min(): https://github.com/vim-jp/issues/issues/1049
          let list = r[min([i, len(r)]) :]
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
  if self.has_characteristics(s:SIZED)
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

function! s:Stream.distinct(...) abort
  if self.has_characteristics(s:DISTINCT)
    return self
  endif
  let stream = deepcopy(s:Stream)
  let stream._characteristics = or(self._characteristics, s:DISTINCT)
  let stream._upstream = self
  if a:0
    let stream._call = s:_get_callfunc_for_func1(a:1, 'distinct()')
    let stream._stringify = a:1
  else
    let stream._call = function('call')
    let stream._stringify = function('string')
  endif
  let stream.__end = 0
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at take_while()'
    endif
    let [list, open] = self._upstream.__take_possible__(a:n)
    if self.has_characteristics(s:SORTED)
      let uniq_list = uniq(list)
    else
      let dup = {}
      let uniq_list = []
      for l:Value in list
        let key = self._call(self._stringify, [l:Value])
        if !has_key(dup, key)
          let uniq_list += [l:Value]
          let dup[key] = 1
        endif
      endfor
    endif
    let self.__end = !open
    return [uniq_list, open]
  endfunction
  function! stream.__estimate_size__() abort
    return self._upstream.__estimate_size__()
  endfunction
  return stream
endfunction

function! s:Stream.sorted(...) abort
  if self.has_characteristics(s:SORTED)
    return self
  endif
  let stream = deepcopy(s:Stream)
  let stream._characteristics = or(self._characteristics, s:SORTED)
  let stream._upstream = self
  let stream.__end = 0
  " see stream.__take_possible__()
  " let stream.__sorted_list = []
  if a:0
    let stream._call = s:_get_callfunc_for_func2(a:1, 'sorted()')
    let stream._comparator = a:1
  endif
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at take_while()'
    endif
    if !has_key(self, '__sorted_list')
      let self.__sorted_list = self._upstream.__take_possible__(1/0)[0]
      if has_key(self, '_comparator')
        call sort(self.__sorted_list, self.__compare__, self)
      else
        call sort(self.__sorted_list)
      endif
    endif
    " min(): https://github.com/vim-jp/issues/issues/1049
    let end_index = min([a:n, len(self.__sorted_list)]) - 1
    let list = self.__sorted_list[: end_index]
    let self.__sorted_list = self.__sorted_list[end_index + 1 :]
    let self.__end = (self.__estimate_size__() > 0)
    return [list, !self.__end]
  endfunction
  function! stream.__compare__(a, b) abort
    return self._call(self._comparator, [a:a, a:b])
  endfunction
  function! stream.__estimate_size__() abort
    if has_key(self, '__sorted_list')
      return len(self.__sorted_list)
    endif
    return self._upstream.__estimate_size__()
  endfunction
  return stream
endfunction

function! s:Stream.limit(n) abort
  if a:n < 0
    throw 'vital: Stream: limit(n): n must be 0 or positive'
  endif
  if a:n ==# 0
    return s:empty()
  endif
  let stream = deepcopy(s:Stream)
  let stream._characteristics = or(self._characteristics, s:SIZED)
  let stream._upstream = self
  let stream.__end = 0
  let stream._n = a:n
  function! stream.__take_possible__(...) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at limit()'
    endif
    let list = self._upstream.__take_possible__(self._n)[0]
    let self.__end = (self.__estimate_size__() ==# 0)
    return [list, !self.__end]
  endfunction
  function! stream.__estimate_size__() abort
    return min([self._n, self._upstream.__estimate_size__()])
  endfunction
  return stream
endfunction

function! s:Stream.skip(n) abort
  if a:n < 0
    throw 'vital: Stream: skip(n): n must be 0 or positive'
  endif
  if a:n ==# 0
    return self
  endif
  let stream = deepcopy(s:Stream)
  let stream._characteristics = self._characteristics
  let stream._upstream = self
  let stream.__end = 0
  let stream.__n = a:n
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at skip()'
    endif
    let open = self.__estimate_size__() > 0
    if self.__n > 0 && open
      let open = self._upstream.__take_possible__(self.__n)[1]
      let self.__n = 0
    endif
    let list = []
    if self.__n ==# 0
      let [list, open] = self._upstream.__take_possible__(a:n)
    endif
    let self.__end = !open
    return [list, open]
  endfunction
  if self.has_characteristics(s:SIZED)
    function! stream.__estimate_size__() abort
      return max([self._upstream.__estimate_size__() - self.__n, 0])
    endfunction
  else
    function! stream.__estimate_size__() abort
      return 1/0
    endfunction
  endif
  return stream
endfunction

function! s:Stream.zip(stream, ...) abort
  return call('s:zip', [self, a:stream] + a:000)
endfunction

function! s:Stream.zip_with_index() abort
  return s:zip(s:iterate(0, 'v:val + 1'), self)
endfunction

function! s:Stream.concat(stream) abort
  return s:concat(self, a:stream)
endfunction

function! s:Stream.reduce(f, ...) abort
  let l:Call = s:_get_callfunc_for_func2(a:f, 'reduce()')
  let list = s:_get_non_empty_list_or_default(
  \                 self, self.__estimate_size__(), a:0 ? [a:1] : s:NONE, 'reduce()')
  let l:Result = list[0]
  for l:Value in list[1:]
    let l:Result = l:Call(a:f, [l:Result, l:Value])
  endfor
  return l:Result
endfunction

function! s:Stream.max(...) abort
  return max(s:_get_non_empty_list_or_default(
  \           self, self.__estimate_size__(), a:0 ? [a:1] : s:NONE, 'max()'))
endfunction

function! s:Stream.max_by(f, ...) abort
  let l:Call = s:_get_callfunc_for_func1(a:f, 'max_by()')
  let list = s:_get_non_empty_list_or_default(
  \           self, self.__estimate_size__(), a:0 ? [a:1] : s:NONE, 'max_by()')
  let result = [list[0], l:Call(a:f, [list[0]])]
  for l:Value in list[1:]
    let n = l:Call(a:f, [l:Value])
    if n > result[1]
      let result = [l:Value, n]
    endif
  endfor
  return result[0]
endfunction

function! s:Stream.min(...) abort
  return min(s:_get_non_empty_list_or_default(
  \           self, self.__estimate_size__(), a:0 ? [a:1] : s:NONE, 'min()'))
endfunction

function! s:Stream.min_by(f, ...) abort
  let l:Call = s:_get_callfunc_for_func1(a:f, 'min_by()')
  let list = s:_get_non_empty_list_or_default(
  \           self, self.__estimate_size__(), a:0 ? [a:1] : s:NONE, 'min_by()')
  let result = [list[0], l:Call(a:f, [list[0]])]
  for l:Value in list[1:]
    let n = l:Call(a:f, [l:Value])
    if n < result[1]
      let result = [l:Value, n]
    endif
  endfor
  return result[0]
endfunction

function! s:Stream.find_first(...) abort
  return s:_get_non_empty_list_or_default(
  \           self, 1, a:0 ? [a:1] : s:NONE, 'find_first()')[0]
endfunction

function! s:Stream.find(f, ...) abort
  let s = self.filter(a:f).limit(1)
  return a:0 ? s.find_first(a:1) : s.find_first()
endfunction

function! s:Stream.any_match(f) abort
  return self.filter(a:f).find_first(s:NONE) isnot s:NONE
endfunction

function! s:Stream.all_match(f) abort
  return self.filter(s:_not(a:f, 'all_match()')).find_first(s:NONE) is s:NONE
endfunction

function! s:Stream.none_match(f) abort
  return self.filter(a:f).find_first(s:NONE) is s:NONE
endfunction

function! s:Stream.string_join(...) abort
  let sep = a:0 ? a:1 : ' '
  return join(self.to_list(), sep)
endfunction

function! s:Stream.group_by(f) abort
  let l:Call = s:_get_callfunc_for_func1(a:f, 'group_by()')
  let l:Result = {}
  for l:Value in self.to_list()
    let key = l:Call(a:f, [l:Value])
    let l:Result[key] = get(l:Result, key, []) + [l:Value]
  endfor
  return l:Result
endfunction

function! s:Stream.to_dict(key_mapper, value_mapper, ...) abort
  let l:CallKM = s:_get_callfunc_for_func1(a:key_mapper, 'to_dict()')
  let l:CallVM = s:_get_callfunc_for_func1(a:value_mapper, 'to_dict()')
  let l:Result = {}
  if a:0
    let l:CallMerge = s:_get_callfunc_for_func2(a:1, 'to_dict()')
    for l:Value1 in self.to_list()
      let key = l:CallKM(a:key_mapper, [l:Value1])
      let l:Value2 = l:CallVM(a:value_mapper, [l:Value1])
      if has_key(l:Result, key)
        let l:Value3 = l:CallMerge(a:1, [l:Result[key], l:Value2])
      else
        let l:Value3 = l:Value2
      endif
      let l:Result[key] = l:Value3
      unlet l:Value1
      unlet l:Value2
      unlet l:Value3
    endfor
  else
    for l:Value in self.to_list()
      let key = l:CallKM(a:key_mapper, [l:Value])
      if has_key(l:Result, key)
        throw 'vital: Stream: to_dict(): duplicated elements exist in stream '
        \   . '(key: ' . string(key . '') . ')'
      endif
      let l:Result[key] = l:CallVM(a:value_mapper, [l:Value])
    endfor
  endif
  return l:Result
endfunction

function! s:Stream.sum() abort
  return self.reduce('v:val[0] + v:val[1]', 0)
endfunction

function! s:Stream.average() abort
  let n = self.__estimate_size__()
  if n ==# 0
    throw 'vital: Stream: average(): empty stream cannot be average()d'
  endif
  return self.reduce('v:val[0] + v:val[1]', 0) / n
endfunction

function! s:Stream.count() abort
  if self.has_characteristics(s:SIZED)
    return len(self.to_list())
  endif
  return 1/0
endfunction

function! s:Stream.to_list() abort
  return self.__take_possible__(self.__estimate_size__())[0]
endfunction

function! s:Stream.foreach(f) abort
  call self.map(a:f).to_list()
endfunction

function! s:_not(f, callee) abort
  if s:Closure.is_closure(a:f)
    return a:f.compose('=!a:1')
  endif
  let type = type(a:f)
  if type is s:t_func
    return '!' . string(a:f) . '(v:val)'
  elseif type is s:t_string
    return '!map([v:val], ' . string(a:f) . ')[0]'
  else
    throw 'vital: Stream: ' . a:callee
    \   . ': invalid type argument was given '
    \   . '(expected funcref, string, or Data.Closure)'
  endif
endfunction

" Get funcref of call()-ish function to call a:f (arity is 0)
" (see also s:_call_func0_expr())
function! s:_get_callfunc_for_func0(f, callee) abort
  if s:Closure.is_closure(a:f)
    return function('s:_call_closure0')
  endif
  let type = type(a:f)
  if type is s:t_func
    return function('call')
  elseif type is s:t_string
    return function('s:_call_func0_expr')
  else
    throw 'vital: Stream: ' . a:callee
    \   . ': invalid type argument was given '
    \   . '(expected funcref, string, or Data.Closure)'
  endif
endfunction

" @vimlint(EVL103, 1, a:args)
function! s:_call_closure0(closure, args) abort
  return a:closure.call()
endfunction
" @vimlint(EVL103, 0, a:args)

" a:expr is passed to v:val (but it is not meaningless value because
" a:expr should not have 'v:val')
" @vimlint(EVL103, 1, a:args)
function! s:_call_func0_expr(expr, args) abort
  return eval(a:expr)
endfunction
" @vimlint(EVL103, 0, a:args)

" Get funcref of call()-ish function to call a:f (arity is 1)
" (see also s:_call_func1_expr())
function! s:_get_callfunc_for_func1(f, callee) abort
  if s:Closure.is_closure(a:f)
    return function('s:_call_closure1')
  endif
  let type = type(a:f)
  if type is s:t_func
    return function('call')
  elseif type is s:t_string
    return function('s:_call_func1_expr')
  else
    throw 'vital: Stream: ' . a:callee
    \   . ': invalid type argument was given '
    \   . '(expected funcref, string, or Data.Closure)'
  endif
endfunction

function! s:_call_closure1(closure, args) abort
  return a:closure.call(a:args[0])
endfunction

" a:args[0] is passed to v:val
function! s:_call_func1_expr(expr, args) abort
  return map(a:args, a:expr)[0]
endfunction

" Get funcref of call()-ish function to call a:f (arity is 2)
" (see also s:_call_func2_expr())
function! s:_get_callfunc_for_func2(f, callee) abort
  if s:Closure.is_closure(a:f)
    return function('s:_call_closure2')
  endif
  let type = type(a:f)
  if type is s:t_func
    return function('call')
  elseif type is s:t_string
    return function('s:_call_func2_expr')
  else
    throw 'vital: Stream: ' . a:callee
    \   . ': invalid type argument was given '
    \   . '(expected funcref, string, or Data.Closure)'
  endif
endfunction

function! s:_call_closure2(closure, args) abort
  return a:closure.call(a:args[0], a:args[1])
endfunction

" List of two elements is passed to v:val
function! s:_call_func2_expr(expr, args) abort
  return map([a:args], a:expr)[0]
endfunction

function! s:_get_non_empty_list_or_default(stream, size, default, callee) abort
  if a:stream.__estimate_size__() ==# 0
    let list = []
  else
    let list = a:stream.__take_possible__(a:size)[0]
  endif
  if !empty(list)
    return list
  endif
  if a:default isnot s:NONE
    return a:default
  else
    throw 'vital: Stream: ' . a:callee .
    \     ': stream is empty and default value was not given'
  endif
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
