" math utilities.

let s:save_cpo = &cpo
set cpo&vim

" XXX Simpler way?
function! s:modulo(n, m)
  let d = a:n * a:m < 0 ? 1 : 0
  return a:n + (-(a:n + (0 < a:m ? d : -d)) / a:m + d) * a:m
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
