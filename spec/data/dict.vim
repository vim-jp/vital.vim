source spec/base.vim

let g:D = vital#of('vital').import('Data.Dict')

Context Data.Dict.make()
  It makes a new dictionary from keys and values
    Should {'one': 1, 'two': 2, 'three': 3} == g:D.make(['one', 'two', 'three'], [1, 2, 3])
  End
  It ignores the extra values
    Should {'one': 1} == g:D.make(['one'], [1, 2, 3])
  End
  It fills the values by 0 if it is short
    Should {'one': 1, 'two': 2, 'three': 0} == g:D.make(['one', 'two', 'three'], [1, 2])
  End
  It fills the values by specified value if it is short
    Should {'one': 1, 'two': 'null', 'three': 'null'} == g:D.make(['one', 'two', 'three'], [1], 'null')
  End
  It converts invalid key to a string
    Should {'[]': 'list', '{}': 'dict', '1.0': 'float'} == g:D.make([[], {}, 1.0], ['list', 'dict', 'float'])
  End
  It throws an error when key is empty string
    try
      call g:D.make(['one', 'two', ''], [1, 2, 'empty'])
      Should 0
    catch /^vital: Data.Dict.make():/
      Should 1
    endtry
  End
End

Context Data.Dict.swap()
  It swaps keys and values
    let a = {'one': 1, 'two': 2, 'three': 3}
    Should {'1': 'one', '2': 'two', '3': 'three'} == g:D.swap(a)
    Should a == {'one': 1, 'two': 2, 'three': 3}
    Should {} == g:D.swap({})
    unlet a
  End

  It converts invalid key to a string
    Should {'[]': 'list', '{}': 'dict', '1.0': 'float'} == g:D.swap({'list': [], 'dict': {}, 'float': 1.0})
  End

End

Context Data.Dict.make_index()
  It makes an index dictionary from a list
    let a = []
    let b = deepcopy(a)
    Should {} == g:D.make_index(a)
    Should a == b
    Should {} == g:D.make_index(a, 5)
    Should a == b
    let a = ['apple', 'orange', 'banana']
    let b = deepcopy(a)
    Should {'apple': 1, 'orange': 1, 'banana': 1} == g:D.make_index(a)
    Should a == b
    unlet a
    unlet b
  End
  It makes an index dictionary with a specified value
    let a = ['apple', 'orange', 'banana']
    let b = deepcopy(a)
    Should {'apple': 'true', 'orange': 'true', 'banana': 'true'} == g:D.make_index(a, 'true')
    Should a == b
    Should {'apple': 5, 'orange': 5, 'banana': 5} == g:D.make_index(a, 5)
    Should a == b
    unlet a
    unlet b
  End

  It converts invalid key to a string
    let a = [[], {}, 1.4]
    let b = deepcopy(a)
    Should {'[]': 1, '{}': 1, '1.4': 1} == g:D.make_index(a)
    Should a == b
    Should {'[]': [1,2,3], '{}': [1,2,3], '1.4': [1,2,3]} == g:D.make_index(a, [1,2,3])
    Should a == b
    unlet a
    unlet b
  End
End

Context Data.Dict.pick()
  It returns filtered dictionary that only has values for the whitelisted
    Should {'apple': 'red', 'melon': 'green'} ==
    \      g:D.pick({'apple': 'red', 'banana': 'yellow', 'melon': 'green'},
    \               ['apple', 'melon'])
    let a = {'one': 1, 'two': 2, 'three': 3}
    let b = deepcopy(a)
    Should {'one': 1, 'three': 3} == g:D.pick(a, ['one', 'three'])
    Should a == b
  End
  It ignores unexisting item of whitelist
    Should {'apple': 'red', 'melon': 'green'} ==
    \      g:D.pick({'apple': 'red', 'banana': 'yellow', 'melon': 'green'},
    \               ['apple', 'orange', 'lemon', 'melon'])
    unlet a
    unlet b
  End
  It returns new dictionary
    let dict = {}
    Should dict isnot g:D.pick(dict, [])
    unlet dict
  End
  It doesn't change the passed dictionary
    let dict = {'apple': 'red', 'banana': 'yellow', 'melon': 'green'}
    let dict2 = deepcopy(dict)
    Should {} == g:D.pick(dict, [])
    Should dict2 == dict
    unlet dict
    unlet dict2
  End
End

Context Data.Dict.omit()
  It returns filtered dictionary that omits the blacklisted
    Should {'banana': 'yellow'} ==
    \      g:D.omit({'apple': 'red', 'banana': 'yellow', 'melon': 'green'},
    \               ['apple', 'melon'])
  End
  It ignores unexisting item of blacklist
    Should {'banana': 'yellow'} ==
    \      g:D.omit({'apple': 'red', 'banana': 'yellow', 'melon': 'green'},
    \               ['apple', 'orange', 'lemon', 'melon'])
  End
  It returns new dictionary
    let dict = {}
    Should dict isnot g:D.omit(dict, [])
    unlet dict
  End
  It doesn't change the passed dictionary
    let dict = {'apple': 'red', 'banana': 'yellow', 'melon': 'green'}
    Should {} == g:D.omit(dict, keys(dict))
    Should {'apple': 'red', 'banana': 'yellow', 'melon': 'green'} == dict
    unlet dict
  End
End

Context Data.Dict.clear()
  It clears the all items of a dictionary
    let dict = {'one': 1, 'two': 2, 'three': 3}
    Should {} == g:D.clear(dict)
    Should dict == {}
  End
  It returns the passed dictionary directly
    let dict = {'one': 1, 'two': 2, 'three': 3}
    Should g:D.clear(dict) is dict
  End
End

Context Data.Dict.max_by()
  It returns a key-and-value list which derives a maximum value in the dictionary through the given expr.
    Should ['foo', -5] == g:D.max_by({'hoge': 3, 'foo': -5, 'hehehe': 1, 'yahoo': 2}, 'len(v:key) * abs(v:val)')
    Should ['bob', '/1/2/3/4'] == g:D.max_by({'alice': '/1/2/3', 'bob': '/1/2/3/4', 'carol': '/1/2', 'dave': '/1'}, 'len(v:val)')
  End
  It throws an exception if the dictionary is empty.
    ShouldThrow g:D.max_by({}, 'len(v:key . v:val)'), /.*/
  End
End

Context Data.Dict.min_by()
  It returns a key-and-value list which derives a minimum value in the dictionary through the given expr.
    Should ['hehehe', 1] == g:D.min_by({'hoge': 3, 'foo': -5, 'hehehe': 1, 'yahoo': 2}, 'len(v:key) * abs(v:val)')
    Should ['dave', '/1'] == g:D.min_by({'alice': '/1/2/3', 'bob': '/1/2/3/4', 'carol': '/1/2', 'dave': '/1'}, 'len(v:val)')
  End
  It throws an exception if the dictionary is empty.
    ShouldThrow g:D.min_by({}, 'len(v:key . v:val)'), /.*/
  End
End

Context Data.Dict.foldl()
  It returns a value gotten from folding the keys and values in the dictionary using the given left-associative expr.
    Should 43 == g:D.foldl('len(v:key) * abs(v:val) + v:memo', 0, {'hoge': 3, 'foo': -5, 'hehehe': 1, 'yahoo': 2})
    Should 80 == g:D.foldl('v:memo - len(v:val)', 100, {'alice': '/1/2/3', 'bob': '/1/2/3/4', 'carol': '/1/2', 'dave': '/1'})
  End
End

Context Data.Dict.foldr()
  It returns a value gotten from folding the keys and values in the dictionary using the given right-associative expr.
    Should 43 == g:D.foldr('len(v:key) * abs(v:val) + v:memo', 0, {'hoge': 3, 'foo': -5, 'hehehe': 1, 'yahoo': 2})
    Should 80 == g:D.foldr('v:memo - len(v:val)', 100, {'alice': '/1/2/3', 'bob': '/1/2/3/4', 'carol': '/1/2', 'dave': '/1'})
  End
End
