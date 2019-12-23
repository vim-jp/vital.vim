" Utilities for Base16.
" RFC 4648 https://tools.ietf.org/html/rfc4648

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:ByteArray = s:V.import('Data.List.Byte')
endfunction

function! s:_vital_depends() abort
  return ['Data.List.Byte']
endfunction

function! s:encode(data) abort
  " 'abc' -> [xx, yy, zz](in hex) -> 'xxyyzz'
  return s:encodebytes(s:ByteArray.from_string(a:data))
endfunction

function! s:encodebin(data) abort
  " 'xxyyzz' -> 'xxyyzz'
  return a:data
endfunction

function! s:encodebytes(data) abort
  " [xx, yy, zz](in hex) -> 'xxyyzz'
  return s:ByteArray.to_hexstring(a:data)
endfunction

function! s:decode(data) abort
  " 'xxyyzz' -> [xx, yy, zz](in hex) -> 'abc'
  return s:ByteArray.to_string(s:decoderaw(a:data))
endfunction

function! s:decoderaw(data) abort
  " 'xxyyzz' -> [xx, yy, zz](in hex)
  " case insensitive / no affect
  return s:ByteArray.from_hexstring(a:data)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
