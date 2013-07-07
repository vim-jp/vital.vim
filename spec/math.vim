source spec/base.vim

let g:M = vital#of('vital').import('Math')

Context Math.modulo()
  It returns modulo.
    Should 1 == g:M.modulo(10, 3)
    Should 2 == g:M.modulo(-10, 3)
    Should -2 == g:M.modulo(10, -3)
    Should -1 == g:M.modulo(-10, -3)
  End
End

Context Math.fib()
  It returns fib if it's less than or equal to 48.
    Should g:M.fib(0) == 0
    Should g:M.fib(1) == 1
    Should g:M.fib(10) == 55
    Should g:M.fib(48) == 512559680
  End
End
