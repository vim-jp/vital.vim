" Java Stream API like streaming library

let s:save_cpo = &cpo
set cpo&vim

" ============= Design of Internal API =============
"
" * a stream works like queue.
"   __take_possible__(n) takes n or less elements from queue.
"
" * __take_possible__(n)
"   * n must be 0 or positive
"     * in order to take all elements from the stream, pass 1/0 (:help expr-/)
"   * this function returns '[list, open]'
"     * 'len(list) <= n'
"     * caller must not invoke this function after 'open == 0' is returned
" * `__estimate_size__()`
"   * this function must not change stream's state
"   * if the number of elements is 'unknown', 1/0 is returned
"     * 'flatmap()' cannot determine the number of elements of the result
"     * 'Stream.of(0,1,2,3).flatmap({n -> repeat([n], n)}).to_list() == [1,2,2,3,3,3]'
"     * 'Stream.of(0,1,2,3).flatmap({n -> repeat([n], n)}).__estimate_size__() == 1/0'
"   * if the stream is finite stream ('self.__has_characteristic__(s:SIZED) == 1'),
"     returns the number of elements
"   * if the stream is infinite stream ('self.__has_characteristic__(s:SIZED) == 0'),
"     returns 1/0
"

let s:NONE = []
lockvar! s:NONE

let s:T_NUMBER = 0
let s:T_STRING = 1
let s:T_FUNC = 2
let s:T_LIST = 3
let s:T_DICT = 4
let s:T_FLOAT = 5
let s:T_BOOL = 6
let s:T_NONE = 7
let s:T_JOB = 8
let s:T_CHANNEL = 9

" let s:ORDERED = 0x01
" let s:DISTINCT = 0x02
" let s:SORTED = 0x04
let s:SIZED = 0x08
" let s:NONNULL = 0x10
" let s:IMMUTABLE = 0x20
" let s:CONCURRENT = 0x40

function! s:of(elem, ...) abort
  return s:_new_from_list([a:elem] + a:000, s:SIZED, 'of()')
endfunction

function! s:chars(str) abort
  return s:_new_from_list(split(a:str, '\zs'), s:SIZED, 'chars()')
endfunction

function! s:lines(str) abort
  let lines = a:str ==# '' ? [] : split(a:str, '\r\?\n', 1)
  return s:_new_from_list(lines, s:SIZED, 'lines()')
endfunction

function! s:from_list(list) abort
  return s:_new_from_list(a:list, s:SIZED, 'from_list()')
endfunction

function! s:from_dict(dict) abort
  return s:_new_from_list(items(a:dict), s:SIZED, 'from_dict()')
endfunction

function! s:empty() abort
  return s:_new_from_list([], s:SIZED, 'empty()')
endfunction

function! s:_new_from_list(list, characteristics, caller) abort
  let stream = s:_new(s:Stream)
  let stream._name = a:caller
  let stream._characteristics = a:characteristics
  let stream.__index = 0
  let stream.__end = 0
  let stream._list = a:list
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at '
      \     . self._name
    endif
    " fix overflow
    let n = self.__index + a:n < a:n ? 1/0 : self.__index + a:n
    let list = s:_slice(self._list, self.__index, n - 1)
    let self.__index = n
    let self.__end = (self.__estimate_size__() ==# 0)
    return [list, !self.__end]
  endfunction
  function! stream.__estimate_size__() abort
    return max([len(self._list) - self.__index, 0])
  endfunction
  return stream
endfunction

" same arguments as Vim script's range()
function! s:range(expr, ...) abort
  if a:0 ==# 0
    let args = [0, a:expr - 1, 1]
  elseif a:0 ==# 1
    let args = [a:expr] + a:000 + [1]
  else
    let args = [a:expr] + a:000
  endif
  if args[2] ==# 0    " E726
    throw 'vital: Stream: range(): stride is 0'
  endif
  if s:_range_size(args, 0) ==# 0
    return s:empty()
  endif
  let stream = s:_new(s:Stream)
  let stream._name = 'range()'
  let stream._characteristics = s:SIZED
  let stream.__index = 0
  let stream._args = args
  let stream.__end = 0
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at range()'
    endif
    if a:n ==# 0
      return [[], 1]
    endif
    " workaround for E727 error when the second argument is too big (e.g.: 1/0)
    " a_i = a0 + (n - 1) * a2
    let args = copy(self._args)
    if args[1] >= a:n
      let args[1] = args[0] + (a:n - 1) * args[2]
    endif
    " 'call(...)' is non-empty and 's:_slice(...)' is also non-empty
    " assert a:n != 0
    let list = s:_slice(call('range', args), self.__index, self.__index + a:n - 1)
    let self.__index += a:n
    let self.__end = self.__estimate_size__() ==# 0
    return [list, !self.__end]
  endfunction
  function! stream.__estimate_size__() abort
    return s:_range_size(self._args, self.__index)
  endfunction
  return stream
endfunction

" a0 <= a1, a2 > 0, a_0 = a0, i >= 0
" a_i = a0 + i * a2
" size([a0,a1,a2],i) = (a1 - a_i) / a2 + 1
"                    = (a1 - a0) / a2 - i + 1
"
" @assert a:args[2] != 0
" @assert len(a:args) >= 3
" @assert a:index >= 0
function! s:_range_size(args, index) abort
  let [a0, a1, a2] = a:args
  if a2 < 0
    return s:_range_size([a1, a0, -a2], a:index)
  elseif a0 > a1
    return 0
  else
    " if a:index exceeds range, it becomes 0 or negative
    return max([(a1 - a0) / a2 - a:index + 1, 0])
  endif
endfunction

function! s:iterate(init, f) abort
  let l:Call = s:_get_callfunc_for_func1(a:f, 'iterate()')
  return s:_inf_stream(
  \ a:f, a:init, l:Call, 'self._call(self._f, [v:val])', 'iterate()'
  \)
endfunction

function! s:generate(f) abort
  let l:Call = s:_get_callfunc_for_func0(a:f, 'generate()')
  return s:_inf_stream(
  \ a:f, l:Call(a:f, []), l:Call, 'self._call(self._f, [])', 'generate()'
  \)
endfunction

function! s:_inf_stream(f, init, call, expr, caller) abort
  let stream = s:_new(s:Stream)
  let stream._name = a:caller
  let stream._characteristics = 0
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
  let stream = s:_new(s:Stream)
  let stream._name = 'generator()'
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
  let stream = s:_new(s:Stream)
  let stream._name = 'zip()'
  let stream._characteristics =
  \ s:_zip_characteristics(map([a:s1, a:s2] + a:000, 'v:val._characteristics'))
  let stream.__end = 0
  let stream._upstream = [a:s1, a:s2] + a:000
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at zip()'
    endif
    let lists = map(copy(self._upstream), 'v:val.__take_possible__(a:n)[0]')
    let smaller = min(map(copy(lists), 'len(v:val)'))
    " lists = [[1,2,3], [4,5,6]], list = [[1,4], [2,5], [3,6]]
    " let list = map(range(smaller), '[lists[0][v:val], lists[1][v:val], ...]')
    let expr = '[' . join(map(range(len(lists)), '''lists['' . v:val . ''][v:val]'''), ',') . ']'
    let list = map(range(smaller), expr)
    let self.__end = (self.__estimate_size__() ==# 0)
    return [list, !self.__end]
  endfunction
  function! stream.__estimate_size__() abort
    return min(map(copy(self._upstream), 'v:val.__estimate_size__()'))
  endfunction
  return stream
endfunction

function! s:_zip_characteristics(characteristics_list) abort
  if len(a:characteristics_list) <= 1
    return a:characteristics_list[0]
  endif
  " or() for SIZED flag. and() for other flags
  let [c1, c2; others] = a:characteristics_list
  let result = or(and(c1, c2), and(or(c1, c2), s:SIZED))
  return s:_zip_characteristics([result] + others)
endfunction

function! s:concat(s1, s2, ...) abort
  let stream = s:_new(s:Stream)
  let stream._name = 'concat()'
  let stream._characteristics =
  \ s:_concat_characteristics(map([a:s1, a:s2] + a:000, 'v:val._characteristics'))
  let stream.__end = 0
  let stream.__read_too_much = []
  let stream._upstream = [a:s1, a:s2] + a:000
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at concat()'
    endif
    " concat buffer and all streams
    let list = []
    if !empty(self.__read_too_much)
      let list = s:_slice(self.__read_too_much, 0, a:n - 1)
      let self.__read_too_much = s:_slice(self.__read_too_much, a:n)
    endif
    for stream in self._upstream
      if len(list) >= a:n
        break
      endif
      if stream.__estimate_size__() > 0
        let list += stream.__take_possible__(a:n - len(list))[0]
      endif
    endfor
    if len(list) > a:n
      let self.__read_too_much = s:_slice(list, a:n)
      let list = s:_slice(list, 0, a:n - 1)
    endif
    " if all of buffer length, streams' __estimate_size__() are 0,
    " it is end of streams
    let sizes = [len(self.__read_too_much)] +
    \           map(copy(self._upstream), 'v:val.__estimate_size__()')
    let self.__end = (max(sizes) ==# 0)
    return [list, !self.__end]
  endfunction
  if and(stream._characteristics, s:SIZED)
    function! stream.__estimate_size__() abort
      let sizes = [len(self.__read_too_much)] +
      \           map(copy(self._upstream), 'v:val.__estimate_size__()')
      return self.__sum__(sizes)
    endfunction
    " 1/0 when overflow
    function! stream.__sum__(sizes) abort
      if len(a:sizes) <= 1
        return a:sizes[0]
      else
        let [size1, size2; others] = a:sizes
        return size1 + size2 >= size1 ?
        \         self.__sum__([size1 + size2] + others) : 1/0
      endif
    endfunction
  else
    function! stream.__estimate_size__() abort
      return 1/0
    endfunction
  endif
  return stream
endfunction

function! s:_concat_characteristics(characteristics_list) abort
  if len(a:characteristics_list) <= 1
    return a:characteristics_list[0]
  endif
  " and() for all flags
  let [c1, c2; others] = a:characteristics_list
  return s:_concat_characteristics([and(c1, c2)] + others)
endfunction


let s:Stream = {}

function! s:Stream.__has_characteristic__(flag) abort
  return !!and(self._characteristics, a:flag)
endfunction

function! s:Stream.peek(f) abort
  let stream = s:_new(s:Stream)
  let stream._name = 'peek()'
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
  let stream = s:_new(s:Stream)
  let stream._name = 'map()'
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
  let stream = s:_new(s:Stream, [s:WithBuffered])
  let stream._name = 'flatmap()'
  let stream._characteristics = self._characteristics
  let stream._upstream = self
  let stream.__end = 0
  let stream._call = s:_get_callfunc_for_func1(a:f, 'flatmap()')
  let stream._f = a:f
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at filter()'
    endif
    let open = (self._upstream.__estimate_size__() > 0)
    if a:n ==# 0
      return [[], open]
    endif
    let list = []
    while open && len(list) < a:n
      let open = self.__read_to_buffer__(a:n)
      let r = s:_slice(self.__buffer, 0, a:n - 1)
      let self.__buffer = s:_slice(self.__buffer, a:n)
      " add results to list. len(l) <= a:n when the loop is end
      for l in map(r, 'self._call(self._f, [v:val])')
        if len(l) + len(list) < a:n
          let list += l
        else
          let end = a:n - len(list)
          let list += s:_slice(l, 0, end - 1)
          let self.__buffer = s:_slice(l, end) + self.__buffer
          break
        endif
      endfor
    endwhile
    let self.__end = !open
    return [list, !self.__end]
  endfunction
  " the number of elements in stream is unknown (decreased, as-is, or increased)
  function! stream.__estimate_size__() abort
    return 1/0
  endfunction
  return stream
endfunction

function! s:Stream.filter(f) abort
  let stream = s:_new(s:Stream)
  let stream._name = 'filter()'
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

function! s:Stream.slice_before(f) abort
  let stream = s:_new(s:Stream, [s:WithBuffered])
  let stream._name = 'slice_before()'
  let stream._characteristics = self._characteristics
  let stream._upstream = self
  let stream.__end = 0
  let stream._call = s:_get_callfunc_for_func1(a:f, 'slice_before()')
  let stream._f = a:f
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at slice_before()'
    endif
    let open = (self._upstream.__estimate_size__() > 0)
    if a:n ==# 0
      return [[], open]
    endif
    let open = self.__read_to_buffer__(a:n)
    if empty(self.__buffer)
      return [[], open]
    endif
    let list = []
    let elem = [self.__buffer[0]]
    let self.__buffer = self.__buffer[1:]
    let do_break = 0
    while open
      let open = self.__read_to_buffer__(a:n - len(list))
      for i in range(len(self.__buffer))
        if self._call(self._f, [self.__buffer[i]])
          let list += [elem]
          if len(list) >= a:n
            let self.__buffer = s:_slice(self.__buffer, i)
            let do_break = 1
            break
          endif
          let elem = [self.__buffer[i]]
        else
          let elem += [self.__buffer[i]]
        endif
      endfor
      if !open && len(list) < a:n
        let list += [elem]
      endif
      if do_break
        break
      endif
      let self.__buffer = []
    endwhile
    return [list, open]
  endfunction
  " the number of elements in stream is unknown (decreased, as-is, or increased)
  function! stream.__estimate_size__() abort
    return 1/0
  endfunction
  return stream
endfunction

" __take_possible__(n): n may be 1/0, so when upstream is infinite stream,
" 'self._upstream.__take_possible__(n)' does not stop
" unless .take(n) was specified in downstream.
" But regardless of whether .take(n) was specified,
" this method must stop for even upstream is infinite stream
" if 'a:f' is not matched at any element in the stream.
let s:BULK_SIZE = 32
function! s:Stream.take_while(f) abort
  let stream = s:_new(s:Stream)
  let stream._name = 'take_while()'
  let stream._characteristics = self._characteristics
  let stream._upstream = self
  let stream.__end = 0
  let stream._call = s:_get_callfunc_for_func1(a:f, 'take_while()')
  let stream._f = a:f
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
      let [r, open] = self._upstream.__take_possible__(s:BULK_SIZE)
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
        unlet l:Value
      endfor
      if !open
        break
      endif
    endwhile
    let self.__end = !open
    return [list, open]
  endfunction
  if self.__has_characteristic__(s:SIZED)
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
  let stream = s:_new(s:Stream)
  let stream._name = 'drop_while()'
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
          let list = s:_slice(r, i)
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
  if self.__has_characteristic__(s:SIZED)
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
  let stream = s:_new(s:Stream)
  let stream._name = 'distinct()'
  let stream._characteristics = self._characteristics
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
    let uniq_list = []
    let open = (self._upstream.__estimate_size__() > 0)
    let dup = {}
    while open && len(uniq_list) < a:n
      let [r, open] = self._upstream.__take_possible__(a:n - len(uniq_list))
      for l:Value in r
        let key = self._call(self._stringify, [l:Value])
        if !has_key(dup, key)
          let uniq_list += [l:Value]
          if len(uniq_list) >= a:n
            let open = 0
            break
          endif
          let dup[key] = 1
        endif
        unlet l:Value
      endfor
    endwhile
    let self.__end = !open
    return [uniq_list, open]
  endfunction
  function! stream.__estimate_size__() abort
    return self._upstream.__estimate_size__()
  endfunction
  return stream
endfunction

function! s:Stream.sorted(...) abort
  let stream = s:_new(s:Stream)
  let stream._name = 'sorted()'
  let stream._characteristics = self._characteristics
  let stream._upstream = self
  let stream.__end = 0
  " if this key doesn't exist,
  " sorted list of upstream elements will be set (first time only)
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
    let list = s:_slice(self.__sorted_list, 0, a:n - 1)
    let self.__sorted_list = s:_slice(self.__sorted_list, a:n)
    let self.__end = (self.__estimate_size__() ==# 0)
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

function! s:Stream.take(n) abort
  if a:n < 0
    throw 'vital: Stream: take(n): n must be 0 or positive'
  endif
  if a:n ==# 0
    return s:empty()
  endif
  let stream = s:_new(s:Stream)
  let stream._name = 'take()'
  let stream._characteristics = or(self._characteristics, s:SIZED)
  let stream._upstream = self
  let stream.__end = 0
  let stream._took_count = 0
  let stream._max_n = a:n
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at take()'
    endif
    let n = min([self._upstream.__estimate_size__(), self._max_n, a:n])
    let [list, open] = self._upstream.__take_possible__(n)
    let self._took_count += len(list)
    let self.__end = !open || self._took_count >= min([self._max_n, a:n])
    return [list, !self.__end]
  endfunction
  function! stream.__estimate_size__() abort
    return min([self._max_n - self._took_count, self._upstream.__estimate_size__()])
  endfunction
  return stream
endfunction

function! s:Stream.drop(n) abort
  if a:n < 0
    throw 'vital: Stream: drop(n): n must be 0 or positive'
  endif
  if a:n ==# 0
    return self
  endif
  let stream = s:_new(s:Stream)
  let stream._name = 'drop()'
  let stream._characteristics = self._characteristics
  let stream._upstream = self
  let stream.__end = 0
  let stream.__n = a:n
  function! stream.__take_possible__(n) abort
    if self.__end
      throw 'vital: Stream: stream has already been operated upon or closed at drop()'
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
  if self.__has_characteristic__(s:SIZED)
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

function! s:Stream.concat(stream, ...) abort
  return call('s:concat', [self, a:stream] + a:000)
endfunction

function! s:Stream.reduce(f, ...) abort
  let l:Call = s:_get_callfunc_for_func2(a:f, 'reduce()')
  let list = self.to_list()
  if a:0 ==# 0 && empty(list)
    throw 'vital: Stream: reduce()' .
    \     ': stream is empty and default value was not given'
  endif
  if a:0 > 0 || empty(list)
    let l:Result = a:1
  else
    let l:Result = list[0]
    let list = list[1:]
  endif
  for l:Value in list
    let l:Result = l:Call(a:f, [l:Result, l:Value])
    unlet l:Value
  endfor
  return l:Result
endfunction

function! s:Stream.first(...) abort
  return s:_get_non_empty_list_or_default(
  \           self, 1, a:0 ? [a:1] : s:NONE, 'first()')[0]
endfunction

function! s:Stream.last(...) abort
  return s:_get_non_empty_list_or_default(
  \           self, self.__estimate_size__(), a:0 ? [a:1] : s:NONE, 'last()')[-1]
endfunction

function! s:Stream.find(f, ...) abort
  let s = self.filter(a:f)
  return a:0 ? s.first(a:1) : s.first()
endfunction

function! s:Stream.any(f) abort
  return self.filter(a:f).first(s:NONE) isnot s:NONE
endfunction

function! s:Stream.all(f) abort
  return self.map(a:f).filter('!v:val').first(s:NONE) is s:NONE
endfunction

function! s:Stream.none(f) abort
  return self.filter(a:f).first(s:NONE) is s:NONE
endfunction

function! s:Stream.group_by(f) abort
  return self.to_dict(a:f, '[v:val]', 'v:val[0] + v:val[1]')
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
      unlet l:Value
    endfor
  endif
  return l:Result
endfunction

function! s:Stream.count(...) abort
  if self.__has_characteristic__(s:SIZED)
    if a:0
      let l:Call = s:_get_callfunc_for_func1(a:1, 'count()')
      return len(filter(self.to_list(), 'l:Call(a:1, [v:val])'))
    else
      return len(self.to_list())
    endif
  endif
  return 1/0
endfunction

function! s:Stream.to_list() abort
  return s:_take_freeze(self, self.__estimate_size__())
endfunction

function! s:Stream.foreach(f) abort
  call self.map(a:f).to_list()
endfunction

function! s:_new(base, ...) abort
  if a:0 ==# 0
    return deepcopy(a:base)
  else
    let base = deepcopy(a:base)
    call map(copy(a:1), 'extend(base, deepcopy(v:val))')
    return base
  endif
endfunction

" NOTE: This requires '_upstream'.
let s:WithBuffered = {'__buffer': []}

" can use 'self.__buffer' instead of 'self._upstream.__take_possible__(n)[0]'
" after this function is invoked
function! s:WithBuffered.__read_to_buffer__(n) abort
  let open = (self._upstream.__estimate_size__() > 0)
  if len(self.__buffer) < a:n && open
    let [r, open] = self._upstream.__take_possible__(a:n - len(self.__buffer))
    let self.__buffer += r
  endif
  return open || !empty(self.__buffer)
endfunction

" safe slice
" https://github.com/vim-jp/issues/issues/1049
function! s:_slice(list, start, ...) abort
  let len = len(a:list)
  let start = min([a:start, len])
  let end = a:0 ? min([a:1, len]) : len
  return a:list[start : end]
endfunction

" Get funcref of call()-ish function to call a:f (arity is 0)
" (see also s:_call_func0_expr())
function! s:_get_callfunc_for_func0(f, caller) abort
  let type = type(a:f)
  if type is s:T_FUNC
    return function('call')
  elseif type is s:T_STRING
    return function('s:_call_func0_expr')
  else
    throw 'vital: Stream: ' . a:caller
    \   . ': invalid type argument was given '
    \   . '(expected funcref or string)'
  endif
endfunction

" a:expr is passed to v:val (but it is not meaningless value because
" a:expr should not have 'v:val')
" @vimlint(EVL103, 1, a:args)
function! s:_call_func0_expr(expr, args) abort
  return eval(a:expr)
endfunction
" @vimlint(EVL103, 0, a:args)

" Get funcref of call()-ish function to call a:f (arity is 1)
" (see also s:_call_func1_expr())
function! s:_get_callfunc_for_func1(f, caller) abort
  let type = type(a:f)
  if type is s:T_FUNC
    return function('call')
  elseif type is s:T_STRING
    return function('s:_call_func1_expr')
  else
    throw 'vital: Stream: ' . a:caller
    \   . ': invalid type argument was given '
    \   . '(expected funcref or string)'
  endif
endfunction

" a:args[0] is passed to v:val
function! s:_call_func1_expr(expr, args) abort
  return map(a:args, a:expr)[0]
endfunction

" Get funcref of call()-ish function to call a:f (arity is 2)
" (see also s:_call_func2_expr())
function! s:_get_callfunc_for_func2(f, caller) abort
  let type = type(a:f)
  if type is s:T_FUNC
    return function('call')
  elseif type is s:T_STRING
    return function('s:_call_func2_expr')
  else
    throw 'vital: Stream: ' . a:caller
    \   . ': invalid type argument was given '
    \   . '(expected funcref or string)'
  endif
endfunction

" List of two elements is passed to v:val
function! s:_call_func2_expr(expr, args) abort
  return map([a:args], a:expr)[0]
endfunction

function! s:_get_non_empty_list_or_default(stream, size, default, caller) abort
  if a:stream.__estimate_size__() ==# 0
    let list = []
  else
    let list = s:_take_freeze(a:stream, a:size)
  endif
  if !empty(list)
    return list
  endif
  if a:default isnot s:NONE
    return a:default
  else
    throw 'vital: Stream: ' . a:caller .
    \     ': stream is empty and default value was not given'
  endif
endfunction

function! s:_take_freeze(stream, size) abort
  let list = a:stream.__take_possible__(a:size)[0]
  call s:_freeze(a:stream)
  return list
endfunction

function! s:_freeze(stream) abort
  let a:stream.__take_possible__ = function('s:_throw_closed_stream_exception')
  let a:stream.__estimate_size__ = function('s:_throw_closed_stream_exception')
  if has_key(a:stream, '_upstream')
    let upstreams = type(a:stream._upstream) is s:T_LIST ?
    \               a:stream._upstream : [a:stream._upstream]
    call map(copy(upstreams), 's:_freeze(v:val)')
  endif
endfunction

function! s:_throw_closed_stream_exception(...) abort dict
  throw 'vital: Stream: stream has already been operated upon or closed at '
  \     . self._name
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
