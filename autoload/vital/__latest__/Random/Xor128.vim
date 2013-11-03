" random number generator using xorshift128
" http://www.jstatsoft.org/v08/i14/paper

let s:save_cpo = &cpo
set cpo&vim


function! s:_vital_loaded(V)
  let s:V = a:V
  let s:B = s:V.import('Bitwise')
  let s:x = 123456789
  let s:y = 362436069
  let s:z = 521288629
  let s:w = 88675123
endfunction

function! s:_vital_depends()
  return ['Bitwise']
endfunction

function! s:srand(...)
  if a:0 == 0
    let s:x = has('reltime') ? reltime()[1] : localtime()
  elseif a:0 == 1
    let s:x = a:1
  else
    throw 'Random.Xor128.srand() too many arguments'
  endif
endfunction

function! s:rand()
  let t = s:B.xor(s:x, s:B.lshift(s:x, 11))
  let s:x = s:y
  let s:y = s:z
  let s:z = s:w
  let s:w = s:B.xor(s:B.xor(s:w, s:B.rshift(s:w, 19)), s:B.xor(t, s:B.rshift(t, 8)))
  return s:w
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
