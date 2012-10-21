let s:save_cpo = &cpo
set cpo&vim

" Vim.Compat: Vim compatibility wrapper functions for different
" versions/patchlevels of Vim.
"
" This module is not for multiple OS compatibilities but for versions of Vim
" itself.

" Patch 7.3.694
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
