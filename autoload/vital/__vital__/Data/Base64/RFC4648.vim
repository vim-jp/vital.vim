" Utilities for Base64. RFC 4648 type
" RFC 4648 http://tools.ietf.org/html/rfc4648.html

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Base64util = s:V.import('Data.Base64.Base64')
  let s:ByteArray = s:V.import('Data.List.Byte')
endfunction

function! s:_vital_depends() abort
  return ['Data.Base64.Base64', 'Data.List.Byte']
endfunction

function! s:encode(data) abort
  return s:encodebytes(s:ByteArray.from_string(a:data))
endfunction

function! s:encodebin(data) abort
  return s:encodebytes(s:ByteArray.from_hexstring(a:data))
endfunction

function! s:encodebytes(data) abort
  return s:Base64util.b64encode(a:data,
        \ s:rfc4648_encode_table,
        \ s:is_padding,
        \ s:padding_symbol)
endfunction

function! s:decode(data) abort
  return s:ByteArray.to_string(s:decoderaw(a:data))
endfunction

function! s:decoderaw(data) abort
  return s:Base64util.b64decode(filter(split(a:data, '\zs'), {idx, c -> !s:is_ignore_symbol(c)}),
        \ s:rfc4648_decode_map,
        \ s:is_padding,
        \ s:is_padding_symbol)
endfunction

let s:is_padding = 1
let s:padding_symbol = '='
let s:is_padding_symbol = {c -> c == s:padding_symbol}
let s:is_ignore_symbol = {c -> 0}

let s:rfc4648_encode_table = [
      \ 'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
      \ 'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
      \ 'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
      \ 'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/']

let s:rfc4648_decode_map = {}
for i in range(len(s:rfc4648_encode_table))
  let s:rfc4648_decode_map[s:rfc4648_encode_table[i]] = i
endfor

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
