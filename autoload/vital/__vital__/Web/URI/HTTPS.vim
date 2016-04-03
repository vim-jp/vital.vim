let s:save_cpo = &cpo
set cpo&vim

let s:HTTP = {}
function! s:_vital_loaded(V) abort
  let s:HTTP = a:V.import('Web.URI.HTTP')
endfunction

function! s:_vital_depends() abort
  return ['Web.URI.HTTP']
endfunction


function! s:canonicalize(uriobj) abort
  return s:HTTP.canonicalize(a:uriobj)
endfunction

function! s:default_port(uriobj) abort
  return '443'
endfunction

" vim:set et ts=2 sts=2 sw=2 tw=0:fen:
