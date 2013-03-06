" Utilities both for list and dict.

let s:save_cpo = &cpo
set cpo&vim

function! s:get_f(collection, key, otherwise)
  " TODO make it work also for list
  if has_key(a:collection, a:key)
    return a:collection[a:key]
  else
    return function(a:otherwise)()
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
