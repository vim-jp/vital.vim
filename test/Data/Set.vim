let s:suite = themis#suite('Data.Set')
let s:assert = themis#helper('assert')

function! s:suite.before()
  let s:S = vital#vital#new().import('Data.Set')
  let s:xs = s:S.set([1,2,3,4,5])
  let s:ys = s:S.set([3,4,5,6,7])
  call themis#func_alias({'set': s:S.set()})
  call themis#func_alias({'frozenset': s:S.frozenset()})
endfunction

function! s:suite.after()
  unlet! s:S
  unlet! s:xs
  unlet! s:ys
  delfunction MyHashFunc
endfunction

function! s:equal_set(set, expect, ...) abort
  call s:assert.equals(sort(a:set.to_list()), sort(a:expect), get(a:, 1, ''))
endfunction

function! MyHashFunc(x) abort
  return tolower(a:x)
endfunction

function! s:suite.set() abort
  call s:equal_set(s:S.set([1,2,3,3]), [1,2,3])
  call s:equal_set(s:S.set(
  \ ['a', 'ab', 'a', 'c', 'ab', function('tr'), function('tr')]),
  \ ['a', 'ab', 'c', function('tr')])
endfunction

function! s:suite.frozenset() abort
  call s:equal_set(s:S.frozenset([1,2,3,3]), [1,2,3])
  call s:equal_set(s:S.frozenset(['a', 'ab', 'a', 'c', 'ab']), ['a', 'ab', 'c'])
endfunction

function! s:suite.pass_hash_func_to_set() abort
  let s = s:S.set(['a', 'ab', 'A', 'c', 'aB'], function('MyHashFunc'))
  call s:equal_set(s, ['a', 'ab', 'c'])
  let x = s
  for i in ['', 'i']
    for method in ['or', 'and', 'xor', 'sub']
      let x = x[i . method](s:S.set([]))
    endfor
  endfor
  call s:assert.equals(x._hash_func, function('MyHashFunc'),
  \ 'return set with same hash func')
endfunction

function! s:suite.pass_hash_func_to_frozenset() abort
  let s = s:S.set(['a', 'ab', 'A', 'c', 'aB'], function('MyHashFunc'))
  call s:equal_set(s, ['a', 'ab', 'c'])
  let x = s
  for method in ['or', 'and', 'xor', 'sub']
    let x = x[method]([])
  endfor
  call s:assert.equals(x._hash_func, function('MyHashFunc'),
  \ 'return set with same hash func')
endfunction

function! s:suite.frozenset_has_not_mutable_methods() abort
  let methods = s:S.set(keys(s:S.set())).sub(keys(s:S.frozenset())).to_list()
  call s:assert.compare(len(methods), '>', 0)
  call s:assert.has_key(methods, 'update')
  call s:assert.has_key(methods, 'add')
  call s:assert.has_key(methods, 'symmetric_difference_update')
endfunction

function! s:suite.in() abort
  call s:assert.true(s:xs.in(1))
  call s:assert.false(s:xs.in(0))
endfunction

function! s:suite.union() abort
  call s:equal_set(s:xs.union(s:ys), [1,2,3,4,5,6,7])
  call s:equal_set(s:xs.union([6,7,8]), [1,2,3,4,5,6,7,8])
endfunction

function! s:suite.or_is_alias_for_union() abort
  call s:assert.equals(s:xs.or, s:xs.union)
endfunction

function! s:suite.intersection() abort
  call s:equal_set(s:xs.intersection(s:ys), [3,4,5])
  call s:equal_set(s:xs.intersection([6,7,8]), [])
endfunction

function! s:suite.and_is_alias_for_intersection() abort
  call s:assert.equals(s:xs.and, s:xs.intersection)
endfunction

function! s:suite.symmetric_difference() abort
  call s:equal_set(s:xs.symmetric_difference(s:ys), [1,2,6,7])
  call s:equal_set(s:xs.symmetric_difference([6,7,8]), [1,2,3,4,5,6,7,8])
endfunction

function! s:suite.xor_is_alias_for_symmetric_difference() abort
  call s:assert.equals(s:xs.xor, s:xs.symmetric_difference)
endfunction

function! s:suite.difference() abort
  call s:equal_set(s:xs.difference(s:ys), [1,2])
  call s:equal_set(s:xs.difference([6,7,8]), [1,2,3,4,5])
endfunction

function! s:suite.sub_is_alias_for_difference() abort
  call s:assert.equals(s:xs.sub, s:xs.difference)
endfunction

function! s:suite.issubset() abort
  call s:assert.false(s:xs.issubset(s:ys))
  call s:assert.false(s:xs.issubset([]))
  call s:assert.true(s:xs.issubset(s:S.set([1,2,3,4,5])))
  call s:assert.true(s:xs.issubset([1,2,3,4,5,6]))
endfunction

function! s:suite.issuperset() abort
  call s:assert.false(s:xs.issuperset(s:ys))
  call s:assert.true(s:xs.issuperset([]))
  call s:assert.true(s:xs.issuperset(s:S.set([1,2,3,4,5])))
  call s:assert.false(s:xs.issuperset([1,2,3,4,5,6]))
endfunction

function! s:suite.le_is_alias_for_issubset() abort
  call s:assert.equals(s:xs.le, s:xs.issubset)
endfunction

function! s:suite.ge_is_alias_for_issuperset() abort
  call s:assert.equals(s:xs.ge, s:xs.issuperset)
endfunction

function! s:suite.lt() abort
  call s:assert.false(s:xs.lt(s:ys))
  call s:assert.false(s:xs.lt([]))
  call s:assert.false(s:xs.lt(s:S.set([1,2,3,4,5])))
  call s:assert.true(s:xs.lt([1,2,3,4,5,6]))
endfunction

function! s:suite.gt() abort
  call s:assert.false(s:xs.gt(s:ys))
  call s:assert.true(s:xs.gt([]))
  call s:assert.false(s:xs.gt(s:S.set([1,2,3,4,5])))
  call s:assert.false(s:xs.gt([1,2,3,4,5,6]))
endfunction

function! s:suite.len() abort
  call s:assert.equals(s:xs.len(), 5)
  call s:assert.equals(s:ys.len(), 5)
endfunction

function! s:suite.to_list() abort
  call s:assert.equals(s:S.set([1,2,3,3,2]).to_list(), [1,2,3])
  call s:assert.equals(s:S.frozenset([1,2,3,3,2]).to_list(), [1,2,3])
endfunction

function! s:suite.ior() abort
  let xs = deepcopy(s:xs)
  let ys = deepcopy(s:ys)
  let r = xs.ior(ys)
  call s:equal_set(xs, [1,2,3,4,5,6,7])
  call s:assert.equals(r, xs)
  call s:assert.is_dict(xs.ior([]), 'returns set object')
endfunction

function! s:suite.update() abort
  let [xs, ys] = [deepcopy(s:xs), deepcopy(s:ys)]
  let r = xs.update(ys)
  call s:equal_set(xs, [1,2,3,4,5,6,7])
  call s:assert.equals(r, 0, 'update returns notiong')
endfunction

function! s:suite.iand() abort
  let [xs, ys] = [deepcopy(s:xs), deepcopy(s:ys)]
  let r = xs.iand(ys)
  call s:equal_set(xs, [3,4,5])
  call s:assert.equals(r, xs)
  call s:assert.is_dict(xs.iand([]), 'returns set object')
endfunction

function! s:suite.intersection_update() abort
  let [xs, ys] = [deepcopy(s:xs), deepcopy(s:ys)]
  let r = xs.intersection_update(ys)
  call s:equal_set(xs, [3,4,5])
  call s:assert.equals(r, 0, 'intersection_update returns notiong')
endfunction

function! s:suite.ixor() abort
  let [xs, ys] = [deepcopy(s:xs), deepcopy(s:ys)]
  let r = xs.ixor(ys)
  call s:equal_set(xs, [1,2,6,7])
  call s:assert.equals(r, xs)
  call s:assert.is_dict(xs.ixor([]), 'returns set object')
endfunction

function! s:suite.symmetric_difference_update() abort
  let [xs, ys] = [deepcopy(s:xs), deepcopy(s:ys)]
  let r = xs.symmetric_difference_update(ys)
  call s:equal_set(xs, [1,2,6,7])
  call s:assert.equals(r, 0, 'symmetric_difference_update returns notiong')
endfunction

function! s:suite.isub() abort
  let [xs, ys] = [deepcopy(s:xs), deepcopy(s:ys)]
  let r = xs.isub(ys)
  call s:equal_set(xs, [1,2])
  call s:assert.equals(r, xs)
  call s:assert.is_dict(xs.isub([]), 'returns set object')
endfunction

function! s:suite.difference_update() abort
  let [xs, ys] = [deepcopy(s:xs), deepcopy(s:ys)]
  let r = xs.difference_update(ys)
  call s:equal_set(xs, [1,2])
  call s:assert.equals(r, 0, 'difference_update returns notiong')
endfunction

function! s:suite.clear() abort
  let xs = deepcopy(s:xs)
  let r = xs.clear()
  call s:equal_set(xs, [])
  call s:assert.equals(r, 0, 'clear returns notiong')
endfunction

function! s:suite.add() abort
  let xs = deepcopy(s:xs)
  let r = xs.add(1)
  call s:equal_set(xs, [1,2,3,4,5])
  let r2 = xs.add(6)
  call s:equal_set(xs, [1,2,3,4,5,6])
  call s:assert.equals(r, 0, 'add returns notiong')
endfunction

function! s:suite.remove() abort
  let xs = deepcopy(s:xs)
  let r = xs.remove(1)
  call s:equal_set(xs, [2,3,4,5])
  call s:assert.equals(r, 0, 'remove returns notiong')
  Throws /vital: Data.Set: the element is not a member/ xs.remove(6)
endfunction

function! s:suite.discard() abort
  let xs = deepcopy(s:xs)
  let r = xs.discard(1)
  let r2 = xs.discard(6)
  call s:equal_set(xs, [2,3,4,5])
  call s:assert.equals(r, 0, 'discard returns notiong')
endfunction

function! s:suite.pop() abort
  let xs = s:S.set([1,2])
  let r = xs.pop()
  call s:equal_set(xs, [2])
  let r2 = xs.pop()
  call s:equal_set(xs, [])
  call s:assert.equals(r, 1)
  call s:assert.equals(r2, 2)
  Throws /vital: Data.Set: set is empty/ xs.pop()
endfunction
