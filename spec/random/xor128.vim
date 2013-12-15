source spec/base.vim

scriptencoding utf-8

let g:X = vital#of('vital').import('Random.Xor128')

Context Random.Xor128.rand()
  It returns the same random number as the C implementations.
    let expected = readfile(expand('<sfile>:p:h').'/xor128_random_numbers_table.txt')
    " call g:X.srand(123456789)
    for e in expected
      Should e == g:X.rand()
    endfor
  End
End

Context Random.Xor128.srand()
  It sets the seed
    call g:X.srand(1)
    let g:a1 = g:X.rand()
    let g:a2 = g:X.rand()
    let g:a3 = g:X.rand()

    call g:X.srand(1)
    Should g:a1 == g:X.rand()
    Should g:a2 == g:X.rand()
    Should g:a3 == g:X.rand()

    call g:X.srand(2)
    Should g:a1 != g:X.rand()
  End
End
