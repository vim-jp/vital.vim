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
