" math utilities.

let s:save_cpo = &cpo
set cpo&vim

" TODO Simpler way?
function! s:modulo(m, n)
  let d = a:m * a:n < 0 ? 1 : 0
  return a:m + (-(a:m + (0 < a:n ? d : -d)) / a:n + d) * a:n
endfunction

function! s:fib(n)
  let [a, b, i] = [0, 1, 0]
  while i < a:n
    let [a, b, i] = [b, a + b, i + 1]
  endwhile
  return a
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
