source spec/base.vim

let g:S = vital#of('vital').import('Data.String')

Context Data.String.wrap()
  It makes a list from the given string, considering linebreak and width like wrap option
    Should ['a', 'hello, world!'] ==# g:S.wrap("a\nhello, world!")
    let [&columns, columns] = [12, &columns]
    Should ['a', 'hello, worl', 'd!'] ==# g:S.wrap("a\nhello, world!")
    let &columns = columns
  End
End
