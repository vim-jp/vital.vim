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

Context Math.lcm()
  It returns least common multiple number.
    Should 6  == g:M.lcm([2, 3])
    Should 6  == g:M.lcm([2, -3])
    Should 42 == g:M.lcm([7, 2, 3, 2])
    Should 0  == g:M.lcm([0])
    Should 0  == g:M.lcm([2, 3, 0])
  End
End

Context Math.gcd()
  It returns greatest common divisor.
    Should 1  == g:M.gcd([2, 3])
    Should 10 == g:M.gcd([20, -30])
    Should 5  == g:M.gcd([5, 20, 30])
    Should 0  == g:M.gcd([0])
    Should 0  == g:M.gcd([2, 3, 0])
  End
End
