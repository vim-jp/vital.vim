function! s:double(x) abort
    return a:x * 2
endfunction

function! s:_square(x) abort
    return a:x * a:x
endfunction

let s:i = 1

function! Vital_test_Vim_ScriptLocal_test_i() abort
  return s:i
endfunction
