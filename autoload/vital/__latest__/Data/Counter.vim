" Data.Counter provides a counter similar to python's collections.Counter
" - https://docs.python.org/3.5/library/collections.html#collections.Counter
" - https://github.com/python/cpython/blob/a49faa270dbdc0ce4cb8b79d98915434e019533a/Lib/collections/__init__.py#L446-L448

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:L = s:V.import('Data.List')
endfunction

function! s:_vital_depends() abort
  return ['Data.List']
endfunction

let s:Counter = {
\   '__type__': 'Counter',
\   '_dict': {}
\ }

" s:new() creates a new instance of Counter object.
" @param {list|string|dict?} countable (optional)
function! s:new(...) abort
  if a:0 > 1
    call s:_throw(printf('.new() expected at most 1 arguments, got %d', a:0))
  endif
  let c = deepcopy(s:Counter)
  if a:0 is# 1
    call call(c.add, a:000, c)
  endif
  return c
endfunction

" .get() returns count for given value, return 0 by default.
" @param {any} value
function! s:Counter.get(value) abort
  return get(get(self._dict, self._hash(a:value), {}), 'count', 0)
endfunction

" .set() set count for given value.
" @param {any} x
function! s:Counter.set(x, count) abort
  call self._init_count(a:x)
  let self._dict[self._hash(a:x)].count = a:count
endfunction

" .add() adds counts from countable instead of replacing them.
" @param {list|string|dict} countable
function! s:Counter.add(countable) abort
  let iter = self._to_iter_countable(a:countable)
  if type(iter) is# type([])
    for E in iter
      call self.set(E, self.get(E) + 1)
      unlet E
    endfor
  elseif type(iter) is# type({})
    for [key, cnt] in items(iter)
      " assert type(cnt) is# type(0)
      call self.set(key, self.get(key) + cnt)
    endfor
  else
    call s:_throw('given argument is not countable')
  endif
endfunction

" .subtract() subtracts count from countable. Counts can be reduced below
" zero. Both the inputs and outputs are allowed to contain zero and negative
" counts.
" @param {list|string|dict|Counter} countable
function! s:Counter.subtract(countable) abort
  let iter = self._to_iter_countable(a:countable)
  if type(iter) is# type([])
    for E in iter
      call self.set(E, self.get(E) - 1)
      unlet E
    endfor
  elseif type(iter) is# type({})
    for [key, cnt] in items(iter)
      " assert type(cnt) is# type(0)
      call self.set(key, self.get(key) - cnt)
    endfor
  else
    call s:_throw('given argument is not countable')
  endif
endfunction

" .union() returns a counter of the maximum of value in either of the input
" counters. It keeps only positive counts.
" @param {Counter|dict} other
" @return {Counter}
function! s:Counter.union(other) abort
  let other_counter = s:_is_counter(a:other) ? a:other : s:new(a:other)
  let result = s:new()
  for [key, dict] in items(self._dict)
    let new_count = other_counter.in(key) ?
    \ max([dict.count, other_counter.get(key)]) : dict.count
    if new_count > 0
      let new = {}
      let new[key] = new_count
      call result.add(new)
    endif
  endfor
  for [key, dict] in items(other_counter._dict)
    if !result.in(key)
      let new_count = self.in(key) ?
      \ max([dict.count, self.get(key)]) : dict.count
      if new_count > 0
        let new = {}
        let new[key] = new_count
        call result.add(new)
      endif
    endif
  endfor
  return result
endfunction

" .intersection() returns a counter of the minimum of corresponding counts.
" It keeps only positive counts.
" @param {Counter|dict} other
" @return {Counter}
function! s:Counter.intersection(other) abort
  let other_counter = s:_is_counter(a:other) ? a:other : s:new(a:other)
  let result = s:new()
  for [key, dict] in items(self._dict)
    if other_counter.in(key)
      let new_count = min([dict.count, other_counter.get(key)])
      if new_count > 0
        let new = {}
        let new[key] = new_count
        call result.add(new)
      endif
    endif
  endfor
  return result
endfunction

" .clear() reset all counts.
function! s:Counter.clear() abort
  let self._dict = {}
endfunction

" .elements() returns a list of elements repeating each as many times as its
" count. Elements are returned in arbitrary order. If an element's count is
" less than one, elements() will ignore it.
function! s:Counter.elements() abort
  let result = []
  for dict in values(self._dict)
    let result += repeat([dict.value], dict.count)
  endfor
  return result
endfunction

" .most_common() returns a list of the n most common elements and their counts
" from the most common to the least. If n is omitted, most_common() returns
" all elements in the counter. Elements with equal counts are ordered
" arbitrarily.
" @param {number?} n (optional)
" @return {list<(any, number)>}
function! s:Counter.most_common(...) abort
  let n = get(a:, 1, 0) - 1
  let tuples = []
  for dict in values(self._dict)
    let tuples += [[dict.value, dict.count]]
  endfor
  return s:L.sort_by(tuples, '-v:val[1]')[:n]
endfunction

" .to_dict() returns count dictionary.
" @return {{string: number}}
function! s:Counter.to_dict() abort
  let result = {}
  for [k, dict] in items(self._dict)
    let result[k] = dict.count
  endfor
  return result
endfunction

" .to_list() returns list of element in the counter. The order is arbitrary.
" @return {list<any>}
function! s:Counter.to_list() abort
  return map(values(self._dict), 'v:val.value')
endfunction

" .values() returns list of count in the counter. The order is arbitrary.
" @return {list<number>}
function! s:Counter.values() abort
  return map(values(self._dict), 'v:val.count')
endfunction

" .in() returns the Number 1 if the given element is in the counter, zero
" otherwise.
function! s:Counter.in(x) abort
  return has_key(self._dict, self._hash(a:x))
endfunction

" .del() deletes the given element from the counter. Does not raise error for
" missing values.
function! s:Counter.del(x) abort
  if self.in(a:x)
    call remove(self._dict, self._hash(a:x))
  endif
endfunction

" .keep_positive() strips elements with a negative or zero count.
function! s:Counter.keep_positive() abort
  for [k, dict] in items(self._dict)
    if dict.count < 1
      call remove(self._dict, k)
    endif
  endfor
endfunction

" .reverse() reverses the sign of counts.
function! s:Counter.reverse() abort
  for [k, dict] in items(self._dict)
    call self.set(k, -dict.count)
  endfor
endfunction

" ._init_count() initializes count dictionary for given value.
" @param {any} x
function! s:Counter._init_count(x) abort
  if !self.in(a:x)
    let self._dict[self._hash(a:x)] = {'count': 0, 'value': a:x}
  endif
endfunction

" ._to_iter_countable() converts countable to easy-to-count-and-iterable type.
" It converts `string` to `list` and `Counter` to `dict`.
" @param {list|string|dict|Counter} countable
" @return {list|dict}
function! s:Counter._to_iter_countable(countable) abort
  return type(a:countable) is# type('') ? split(a:countable, '\zs')
  \ : s:_is_counter(a:countable) ? a:countable.to_dict()
  \ : a:countable
endfunction

" ._hash() returns hash key for given value.
function! s:Counter._hash(x) abort
  return type(a:x) is# type('') ? a:x : string(a:x)
endfunction

" Helper:

function! s:_is_counter(x) abort
  return type(a:x) is# type({}) && get(a:x, '__type__', '') is# 'Counter'
endfunction

function! s:_throw(message) abort
  throw 'vital: Data.Counter: ' . a:message
endfunction
