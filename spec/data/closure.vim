source spec/base.vim

let g:C = vital#of('vital').import('Data.Closure')

Context Data.List.from_operator()
  It makes a closure value based on a given operator as a string
    let plus = g:C.from_operator('+')
    Should 3 == plus.call(1, 2)
  End
End
