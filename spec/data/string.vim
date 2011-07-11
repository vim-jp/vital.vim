source spec/base.vim

let g:S = vital#of('vital').import('Data.String')

Context Data.String.wrap()
  It makes a list from the given string, considering linebreak and width like wrap option
    Should ['hello, world!'] ==# g:S.wrap('hello, world!')
    let [&columns, columns] = [12, &columns]
    Should ['hello, world', '!'] ==# g:S.wrap('hello, world!')
    let &columns = columns
  End
End
