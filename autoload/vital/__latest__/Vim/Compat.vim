let s:save_cpo = &cpo
set cpo&vim

" Vim.Compat: Vim compatibility wrapper functions for different
" versions/patchlevels of Vim.
"
" This module is not for multiple OS compatibilities but for versions of Vim
" itself.

" e.g.)
" echo s:has_version('7.3.629')
" echo s:has_version('7.3')
function! s:has_version(version)
  let versions = split(a:version, '\.')
  if len(versions) == 2
    let versions += [0]
  elseif len(versions) != 3
    return 0
  endif
  let vim_version = versions[0] * 100 + versions[1]
  let patch_level = versions[2]
  return v:version < vim_version ||
  \     (v:version == vim_version &&
  \       (patch_level == 0 || has('patch' . patch_level)))
endfunction

" Patch 7.3.694
if exists('*shiftwidth')
  function! s:shiftwidth()
    return shiftwidth()
  endfunction
elseif s:has_version('7.3.629')
  " 7.3.629: When 'shiftwidth' is zero use the value of 'tabstop'.
  function! s:shiftwidth()
    return &shiftwidth == 0 ? &tabstop : &shiftwidth
  endfunction
else
  function! s:shiftwidth()
    return &shiftwidth
  endfunction
endif

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
