source spec/base.vim

scriptencoding utf-8

let g:X = vital#of('vital').import('Random.Xor128')

Context Random.Xor128.rand()
  It returns the same random number as the C implementations.
    let expected = readfile(expand('<sfile>:p:h').'/xor128_random_numbers_table.txt')
    for e in expected
      Should e == g:X.rand()
    endfor
  End
End

