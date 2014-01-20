source spec/base.vim

let g:C = vital#of('vital').import('Data.Closure')

Context Data.List.from_operator()
  It makes a closure value based on a given operator as a string
    let plus = g:C.from_operator('+')
    Should 3 == plus.call(1, 2)

    " let dot = g:C.from_operator('.')
    " Should 1.2 == dot.call(1, 2)
    " Should 'hello world' == dot.call('hello', 'world')
  End
End
