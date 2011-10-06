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
