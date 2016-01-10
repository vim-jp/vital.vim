let s:save_cpo = &cpo
set cpo&vim

let s:HTTP = {}
function! s:_vital_loaded(V) abort
  let s:HTTP = a:V.import('Web.URI.HTTP')
endfunction

function! s:_vital_depends() abort
  return ['Web.URI.HTTP']
endfunction

function! s:new(super) abort
  return s:HTTP.new(a:super)
endfunction


" In order to let s:HTTP.canonicalize()
" calls s:HTTPS.default_port(), pass self.
function! s:canonicalize() dict abort
  return call(s:HTTP.canonicalize, [], self)
endfunction

function! s:default_port() dict abort
  return '443'
endfunction

" vim:set et ts=2 sts=2 sw=2 tw=0:fen:
