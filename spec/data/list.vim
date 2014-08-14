source spec/base.vim

let g:L = vital#of('vital').import('Data.List')

Context Data.List.pop()
  It removes the last element from a list and returns that element
    let a = [1,2,3]
    Should 3 == g:L.pop(a)
    Should [1, 2] == a
    Should 2 == g:L.pop(a)
    Should [1] == a
    Should 1 == g:L.pop(a)
    Should [] == a
    Should 9 == g:L.pop(range(10))
  End
  It causes an error when the list is empty
    try
      call g:L.pop([])
      Should 0
    catch /^Vim(\w*):E684:/
      Should 1
    endtry
  End
End

Context Data.List.push()
  It appends an element to a list and returns the list itself
    let a = []
    Should [1] == g:L.push(a, 1)
    Should [1] == a
    Should [1,2] == g:L.push(a, 2)
    Should [1,2] == a
    Should [1, 2, 3, 4] == g:L.push([1, 2, 3], 4)
    Should [7, 8, 9, 10] == g:L.push(range(7, 9), 10)
  End
End

Context Data.List.shift()
  It removes the first element from a list and returns that element
    let a = [1,2,3]
    Should 1 == g:L.shift(a)
    Should [2,3] == a
    Should 2 == g:L.shift(a)
    Should [3] == a
    Should 3 == g:L.shift(a)
    Should [] == a
    Should 0 == g:L.shift(range(10))
  End
  It causes an error when the list is empty
    try
      call g:L.shift([])
      Should 0
    catch /^Vim(\w*):E684:/
      Should 1
    endtry
  End
End

Context Data.List.unshift()
  It inserts an element to the head of a list and returns the list itself
    let a = []
    Should [1] == g:L.unshift(a, 1)
    Should [1] == a
    Should [2,1] == g:L.unshift(a, 2)
    Should [2,1] == a
    Should [4, 1, 2, 3] == g:L.unshift([1, 2, 3], 4)
    Should [10, 7, 8, 9] == g:L.unshift(range(7, 9), 10)
  End
End

Context Data.List.cons()
  It makes new list which first item is {val} and the rest of items are {list}.
    let a = []
    Should g:L.cons(1, a) == [1]
    Should [] == a
    let a = [1]
    Should g:L.cons(2, a) == [2, 1]
    Should [1] == a
    Should g:L.cons(1, [2, 3]) == [1, 2, 3]
    Should g:L.cons(1, []) == [1]
    Should g:L.cons([1], [2, 3]) == [[1], 2, 3]
  End
End

Context Data.List.conj()
  It makes new list which last items are {val} and the preceding items remain {list}.
    let a = []
    Should g:L.conj(a, 1) == [1]
    Should [] == a
    let a = [1]
    Should g:L.conj(a, 2) == [1, 2]
    Should [1] == a
    Should g:L.conj([2, 3], 1) == [2, 3, 1]
    Should g:L.conj([], 1) == [1]
    Should g:L.conj([2, 3], [1]) == [2, 3, [1]]
  End
End

Context Data.List.uniq()
  It makes a list unique
    let a = ['vim', 'emacs', 'vim', 'vim']
    Should ['vim', 'emacs'] == g:L.uniq(a)
    Should a == ['vim', 'emacs', 'vim', 'vim']
    Should [1.23, [1]] == g:L.uniq([1.23, [1], [1], 1.23])
    Should [{'a': 0, 'b': 1}] == g:L.uniq([{'a': 0, 'b': 1}, {'b': 1, 'a': 0}])
  End

  It supports empty strings as well
    Should ['', 'v', 'vv'] == g:L.uniq(['', '', 'v', 'vv', '', 'vv', 'v'])
  End
End

Context Data.List.uniq_by()
  It makes a list unique based on given expression
    Should [
    \ 'vim', 'emacs', 'gVim'
    \ ] == g:L.uniq_by([
    \ 'vim', 'Vim', 'VIM', 'emacs', 'Emacs', 'EMACS', 'gVim', 'GVIM'
    \ ], 'tolower(v:val)')
  End
End

Context Data.List.clear()
  It clears the all items of a list
    let list = [1, 2, 3]
    Should [] == g:L.clear(list)
    Should list == []
  End
  It returns the passed list directly
    let list = [1, 2, 3]
    Should g:L.clear(list) is list
    Should list == []
  End
  It has no effects for empty list
    let list = []
    Should g:L.clear(list) == []
    Should list == []
  End
End

Context Data.List.max_by()
  It returns a maximum value in the list through the given expr.
    Should 'hehehe' ==# g:L.max_by(['hoge', 'foo', 'hehehe', 'yahoo'], 'len(v:val)')
    Should -50 == g:L.max_by([20, -50, -15, 30], 'abs(v:val)')
  End
  It returns 0 if the list is empty.
    Should 0 == g:L.max_by([], 'v:val')
  End
End

Context Data.List.min_by()
  It returns a minimum value in the list through the given expr.
    Should 'foo' ==# g:L.min_by(['hoge', 'foo', 'hehehe', 'yahoo'], 'len(v:val)')
    Should -15 == g:L.min_by([20, -50, -15, 30], 'abs(v:val)')
  End
  It returns 0 if the list is empty.
    Should 0 == g:L.min_by([], 'v:val')
  End
End

Context Data.List.span()
  It splits a list into two lists. The former is until the given condition doesn't satisfy.
    Should [[1, 3], [5, 2]] == g:L.span('v:val < 5', [1, 3, 5, 2])
    Should [[], [1, 2, 3, 4, 5]] == g:L.span('v:val > 3', [1, 2, 3, 4, 5])
    Should [[1, 2], [3, 4, 5]] == g:L.span('v:val < 3', [1, 2, 3, 4, 5])
  End

  It of course handles list of list.
    Should [[[1], [2, 3]], [[], [4]]] ==
          \ g:L.span('len(v:val) > 0', [[1], [2, 3], [], [4]])
  End
End

Context Data.List.break()
  It splits a list into two lists. The latter is from the given condition satisfies.
    Should [[1, 3], [5, 2]] == g:L.break('v:val == 5', [1, 3, 5, 2])
    Should [[1, 2, 3], [4, 5]] == g:L.break('v:val > 3', [1, 2, 3, 4, 5])
    Should [[], [1, 2, 3, 4, 5]] == g:L.break('v:val < 3', [1, 2, 3, 4, 5])
  End

  It of course handles list of list.
    Should [[[1], [2, 3]], [[], [4]]] ==
          \ g:L.break('len(v:val) == 0', [[1], [2, 3], [], [4]])
  End
End

Context Data.List.take_while()
  It creates a list from another one, it inspects the original list and takes from its elements to the moment when the condition fails, then it stops processing
    Should [1, 3] == g:L.take_while('v:val < 5', [1, 3, 5, 2])
    Should [] == g:L.take_while('v:val > 3', [1, 2, 3, 4, 5])
    Should [1, 2] == g:L.take_while('v:val < 3', [1, 2, 3, 4, 5])
  End

  It of course handles list of list.
    Should [[1], [2, 3]] ==
          \ g:L.take_while('len(v:val) > 0', [[1], [2, 3], [], [4]])
  End
End

Context Data.List.partition()
  It takes a predicate a list and returns the pair of lists of elements which do and do not satisfy the predicate.
    Should [[0, 2, 4], [1, 3]] == g:L.partition('v:val % 2 == 0', range(5))
  End
End

Context Data.List.all()
  It returns true if all items in the list fulfill the condition.
    Should g:L.all('v:val % 2 == 0', [2, 8, 4, 6])
    Should !g:L.all('v:val % 2 == 0', [2, 8, 5, 6])
    Should g:L.all('0 < v:val', [2, 8, 4, 6])
    Should !g:L.all('0 < v:val', [2, 0, 4, 6])
  End
  It returns true if the list is empty.
    Should g:L.all('v:val', [])
  End
End

Context Data.List.any()
  It returns true if at least one item in the list fulfills the condition.
    Should !g:L.any('v:val % 2 == 1', [2, 8, 4, 6])
    Should g:L.any('v:val % 2 == 1', [2, 8, 5, 6])
    Should !g:L.any('0 >= v:val', [2, 8, 4, 6])
    Should g:L.any('0 >= v:val', [2, 0, 4, 6])
  End
  It returns false if the list is empty.
    Should !g:L.any('v:val', [])
  End
End

Context Data.List.and()
  It returns the conjunction of a boolean list.
    Should g:L.and([1, 1, 1, 1])
    Should !g:L.and([1, 0, 1, 1])
    Should !g:L.and([0, 0, 0, 0])
  End
  It returns true if the list is empty.
    Should g:L.and([])
  End
End

Context Data.List.and()
  It returns the disjunction of a boolean list.
    Should g:L.or([1, 1, 1, 1])
    Should g:L.or([1, 0, 1, 1])
    Should !g:L.or([0, 0, 0, 0])
  End
  It returns false if the list is empty.
    Should !g:L.or([])
  End
End

Context Data.List.map_accum()
  It is TODO
    Should [11, 12, 13] == g:L.map_accum('[v:val + v:memo, v:memo]', [1, 2, 3], 10)
    Should [11, 13, 15] == g:L.map_accum('[v:val + v:memo, v:memo + 1]', [1, 2, 3], 10)
  End
End

Context Data.List.foldl()
  It folds a list from left
    Should 55 == g:L.foldl('v:memo + v:val', 0, range(1, 10))
    Should [[[], 1], 2] == g:L.foldl('[v:memo, v:val]', [], [1, 2])
  End

  It does nothing if the list is empty
    Should 123 == g:L.foldl('echoerr omg', 123, [])
  End
End

Context Data.List.foldl1()
  It folds a list from left
    Should 55 == g:L.foldl1('v:memo + v:val', range(1, 10))
    Should [1, 2] == g:L.foldl1('[v:memo, v:val]', [1, 2])
  End

  It causes an error when the list is empty
    try
      call g:L.foldl1('123', [])
      Should 0
    catch /^foldl1$/
      Should 1
    endtry
  End
End

Context Data.List.foldr()
  It folds a list from right
    Should 55 == g:L.foldr('v:memo + v:val', 0, range(1, 10))
    Should [[[], 2], 1] == g:L.foldr('[v:memo, v:val]', [], [1, 2])
  End

  It does nothing if the list is empty
    Should 123 == g:L.foldr('echoerr omg', 123, [])
  End
End

Context Data.List.foldr1()
  It folds a list from left
    Should 55 == g:L.foldr1('v:memo + v:val', range(1, 10))
    Should [2, 1] == g:L.foldr1('[v:memo, v:val]', [1, 2])
  End

  It causes an error when the list is empty
    try
      call g:L.foldr1('123', [])
      Should 0
    catch /^foldr1$/
      Should 1
    endtry
  End
End

Context Data.List.zip()
  It returns mixed list from arguments
    Should g:L.zip([1,2,3]) ==# [[1],[2],[3]]
    Should g:L.zip([1,2,3],[4,5,6],[7,8,9]) ==# [[1,4,7],[2,5,8],[3,6,9]]
    Should g:L.zip([1,2,3],[4,5],[7,8,9]) ==# [[1,4,7],[2,5,8]]
  End
End

Context Data.List.with_index()
  It returns list with index
    Should g:L.with_index(['a', 'b', 'c']) ==# [['a', 0], ['b', 1], ['c', 2]]
    Should g:L.with_index(['a', 'b', 'c'], 3) ==# [['a', 3], ['b', 4], ['c', 5]]
  End
End

Context Data.List.flatten()
  It returns list flatten
    Should g:L.flatten(['a', ['b'], 'c']) ==# ['a', 'b', 'c']
    Should g:L.flatten(['a', [['b'], 'c']]) ==# ['a', 'b', 'c']
    Should g:L.flatten([['a', ['b']], 'c']) ==# ['a', 'b', 'c']
    Should g:L.flatten(['a', [[['b']], 'c']]) ==# ['a', 'b', 'c']
    Should g:L.flatten(['a', [[['b']], 'c']], 1) ==# ['a', [['b']], 'c']
    Should g:L.flatten([[['a']], [[['b']], 'c']], 1) ==# [['a'], [['b']], 'c']
    Should g:L.flatten([[['a']], [[['b']], 'c']], 2) ==# ['a', ['b'], 'c']
    Should g:L.flatten([[['a']], [[['b']], 'c']], 3) ==# ['a', 'b', 'c']
    Should g:L.flatten([[['a']], [[['b']], 'c']], 4) ==# ['a', 'b', 'c']
    Should g:L.flatten([[['a']], [[['b']], 'c']], 10) ==# ['a', 'b', 'c']
  End
End

Context Data.List.has_common_items()
  It returns true/false if given Lists does/doesn't have any common item(s)
    Should g:L.has_common_items(['a', 'b', 'c'], ['b', 'c'])
    Should g:L.has_common_items(['a', 'c'], ['b', 'c'])
    Should !g:L.has_common_items(['a'], ['b', 'c'])
    Should !g:L.has_common_items([], ['b', 'c'])
    Should !g:L.has_common_items(['a'], [])
    Should !g:L.has_common_items([], [])
  End
End

Context Data.List.group_by()
  It returns grouped dictionary
    Should g:L.group_by([], 'len(v:val)') ==# {}
    Should g:L.group_by(['a', 'b', 'ab', 'bc'], 'len(v:val)') ==# {'1': ['a', 'b'], '2': ['ab', 'bc']}
    Should g:L.group_by(['a', 'b', 'ab', 'bc'], 'v:val[0]') ==# {'a': ['a', 'ab'], 'b': ['b', 'bc']}
    Should g:L.group_by(range(4), 'v:val % 2 == 0 ? "aa" : 1.0') ==# {'aa': [0, 2], '1.0': [1, 3]}
  End
End

function! My_predicate(a, b)
    return a:a - a:b
endfunction

Context Data.List.binary_search()
  It search a list and return the index if success
    Should g:L.binary_search([1, 3, 5, 7], 1) == 0
    Should g:L.binary_search([1, 3, 5, 7], 3) == 1
    Should g:L.binary_search([1, 3, 5, 7], 5) == 2
    Should g:L.binary_search([1, 3, 5, 7], 7) == 3

    Should g:L.binary_search([1, 3, 5, 7], 1, 'My_predicate') == 0
    Should g:L.binary_search([1, 3, 5, 7], 3, 'My_predicate') == 1
    Should g:L.binary_search([1, 3, 5, 7], 5, 'My_predicate') == 2
    Should g:L.binary_search([1, 3, 5, 7], 7, 'My_predicate') == 3

    let f = {}
    function! f.func(a, b) dict
      return a:a - a:b
    endfunction

    Should g:L.binary_search([1, 3, 5, 7], 1, f.func, f) == 0
    Should g:L.binary_search([1, 3, 5, 7], 3, f.func, f) == 1
    Should g:L.binary_search([1, 3, 5, 7], 5, f.func, f) == 2
    Should g:L.binary_search([1, 3, 5, 7], 7, f.func, f) == 3

    Should g:L.binary_search([1, 3, 5, 7], 1, f.func) == 0
    Should g:L.binary_search([1, 3, 5, 7], 3, f.func) == 1
    Should g:L.binary_search([1, 3, 5, 7], 5, f.func) == 2
    Should g:L.binary_search([1, 3, 5, 7], 7, f.func) == 3

    function! f.bylength(a, b) dict
      return len(a:a) - len(a:b)
    endfunction

    Should g:L.binary_search(['a', 'aa', 'aaa', 'aaaa'], 'a', f.bylength) == 0
    Should g:L.binary_search(['a', 'aa', 'aaa', 'aaaa'], 'aa', f.bylength) == 1
    Should g:L.binary_search(['a', 'aa', 'aaa', 'aaaa'], 'aaa', f.bylength) == 2
    Should g:L.binary_search(['a', 'aa', 'aaa', 'aaaa'], 'aaaa', f.bylength) == 3
    Should g:L.binary_search(['a', 'aa', 'aaa', 'aaaa'], 'aaaaa', f.bylength) == -1

    " Corner cases
    Should g:L.binary_search([1], 1) == 0
  End

  It returns -1 if failed
    Should g:L.binary_search([1, 3, 5, 7], 2) == -1
    Should g:L.binary_search([1, 3, 5, 7], 2, 'My_predicate') == -1
    Should g:L.binary_search([], 1) == -1
    Should g:L.binary_search([], 1, 'My_predicate') == -1

    let f = {}
    function! f.func(a, b) dict
        return a:a - a:b
    endfunction

    Should g:L.binary_search([1, 3, 5, 7], 2, f.func, f) == -1
    Should g:L.binary_search([], 1, f.func, f) == -1
    Should g:L.binary_search([1, 3, 5, 7], 2, f.func) == -1
    Should g:L.binary_search([], 1, f.func) == -1
  End
End
