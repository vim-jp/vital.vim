let s:save_cpo = &cpo
set cpo&vim

let s:super = {}
function! s:on_loaded(super) abort
  let s:super = a:super
endfunction

" The following four URIs are equivalent:
" * http://example.com
" * http://example.com/
" * http://example.com:/
" * http://example.com:80/
"
" https://tools.ietf.org/html/rfc3986#section-6.2.3
function! s:canonicalize() dict abort
  if s:super.path() ==# ''
    call s:super.path('/')
  endif
  if s:super.port() ==# self.default_port()
    call s:super.port('')
  endif
endfunction

function! s:default_port() dict abort
  return '80'
endfunction

" vim:set et ts=2 sts=2 sw=2 tw=0:fen:
