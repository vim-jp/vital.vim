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
    Should {'1': 'one', '2': 'two', '3': 'three'} == g:D.swap({'one': 1, 'two': 2, 'three': 3})
  End
End

Context Data.Dict.make_index()
  It makes an index dictionary from a list
    Should {'apple': 1, 'orange': 1, 'banana': 1} == g:D.make_index(['apple', 'orange', 'banana'])
  End
  It makes an index dictionary with a specified value
    Should {'apple': 'true', 'orange': 'true', 'banana': 'true'} == g:D.make_index(['apple', 'orange', 'banana'], 'true')
  End
End

Context Data.Dict.pick()
  It returns filtered dictionary that only have values for the whitelisted
    Should {'apple': 'red', 'melon': 'green'} ==
    \      g:D.pick({'apple': 'red', 'banana': 'yellow', 'melon': 'green'},
    \               ['apple', 'melon'])
  End
  It ignores unexisting item of whitelist
    Should {'apple': 'red', 'melon': 'green'} ==
    \      g:D.pick({'apple': 'red', 'banana': 'yellow', 'melon': 'green'},
    \               ['apple', 'orange', 'lemon', 'melon'])
  End
  It returns new dictionary
    let dict = {}
    Should dict isnot g:D.pick(dict, [])
    unlet dict
  End
  It doesn't change the passed dictionary
    let dict = {'apple': 'red', 'banana': 'yellow', 'melon': 'green'}
    Should {} == g:D.pick(dict, [])
    Should {'apple': 'red', 'banana': 'yellow', 'melon': 'green'} == dict
    unlet dict
  End
End

Context Data.Dict.omit()
  It returns filtered dictionary that omit the blacklisted
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
    call g:D.clear(dict)
    Should dict == {}
  End
  It returns the passed dictionary directly
    let dict = {'one': 1, 'two': 2, 'three': 3}
    Should g:D.clear(dict) is dict
  End
End
