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
function! s:has_version(version) abort
  let versions = split(a:version, '\.')
  if len(versions) == 2
    let versions += [0]
  elseif len(versions) != 3
    return 0
  endif
  let vim_version = versions[0] * 100 + versions[1]
  let patch_level = versions[2]
  return v:version > vim_version ||
  \     (v:version == vim_version &&
  \       (patch_level == 0 || has('patch' . patch_level)))
endfunction

" Patch 7.3.694
if exists('*shiftwidth')
  function! s:shiftwidth() abort
    return shiftwidth()
  endfunction
elseif s:has_version('7.3.629')
  " 7.3.629: When 'shiftwidth' is zero use the value of 'tabstop'.
  function! s:shiftwidth() abort
    return &shiftwidth == 0 ? &tabstop : &shiftwidth
  endfunction
else
  function! s:shiftwidth() abort
    return &shiftwidth
  endfunction
endif

" Patch 7.4.503
if s:has_version('7.4.503')
  function! s:writefile(...) abort
    return call('writefile', a:000)
  endfunction
else
  function! s:writefile(list, fname, ...) abort
    let flags = get(a:000, 0, '')
    if flags !~ 'a'
      return writefile(a:list, a:fname, flags)
    endif
    let f = tempname()
    let r = writefile(a:list, f, substitute(flags, 'a', '', 'g'))
    if has("win32") || has("win64")
      silent! execute "!type ".shellescape(f) ">>".shellescape(a:fname)
    else
      silent! execute "!cat ".shellescape(f) ">>".shellescape(a:fname)
    endif
    call delete(f)
    return r
  endfunction
endif

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
