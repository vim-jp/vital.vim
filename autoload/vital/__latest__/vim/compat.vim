let s:save_cpo = &cpo
set cpo&vim

if exists('*shiftwidth')
  function! s:shiftwidth()
    return shiftwidth()
  endfunction
else
  function! s:shiftwidth()
    return &shiftwidth
  endfunction
endif

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
