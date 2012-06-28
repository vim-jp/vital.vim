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
