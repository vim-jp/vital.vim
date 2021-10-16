let s:save_cpo = &cpo
set cpo&vim

" The following four URIs are equivalent:
" * http://example.com
" * http://example.com/
" * http://example.com:/
" * http://example.com:80/
"
" https://tools.ietf.org/html/rfc3986#section-6.2.3
function! s:canonicalize(uriobj) abort
  if a:uriobj.path() ==# ''
    call a:uriobj.path('/')
  endif
  if a:uriobj.port() ==# a:uriobj.default_port()
    call a:uriobj.port('')
  endif
endfunction

" @vimlint(EVL103, 1, a:uriobj)
function! s:default_port(uriobj) abort
  return '80'
endfunction
" @vimlint(EVL103, 0, a:uriobj)

" vim:set et ts=2 sts=2 sw=2 tw=0:fen:
