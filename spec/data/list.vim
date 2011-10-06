source spec/base.vim

let g:L = vital#of('vital').import('Data.List')

Context Data.List.uniq()
  It makes a list unique
    Should ['vim', 'emacs'] == g:L.uniq(['vim', 'emacs', 'vim', 'vim'])
    Should [1.23, [1]] == g:L.uniq([1.23, [1], [1], 1.23])
    Should [{'a': 0, 'b': 1}] == g:L.uniq([{'a': 0, 'b': 1}, {'b': 1, 'a': 0}])
  End

  It supports empty strings as well
    Should ['', 'v', 'vv'] == g:L.uniq(['', '', 'v', 'vv', '', 'vv', 'v'])
  End

  It makes a list unique based on given expression
    Should [
    \ 'vim', 'emacs', 'gVim'
    \ ] == g:L.uniq([
    \ 'vim', 'Vim', 'VIM', 'emacs', 'Emacs', 'EMACS', 'gVim', 'GVIM'
    \ ], 'tolower(v:val)')
  End
End

Context Data.List.span()
  It splits a list into two lists. The former is until the given condition doesn't satisfy.
    Should [[1, 3], [5, 2]] == g:L.span('v:val < 5', [1, 3, 5, 2])
  End
End

Context Data.List.break()
  It splits a list into two lists. The latter is from the given condition satisfies.
    Should [[1, 3], [5, 2]] == g:L.break('v:val == 5', [1, 3, 5, 2])
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
    catch
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

