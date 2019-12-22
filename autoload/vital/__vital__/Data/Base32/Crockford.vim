" Utilities for Base32. Crockford's type
" https://www.crockford.com/base32.html

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Base32util = s:V.import('Data.Base32.Base32')
  let s:ByteArray = s:V.import('Data.List.Byte')
endfunction

function! s:_vital_depends() abort
  return ['Data.Base32.Base32', 'Data.List.Byte']
endfunction

function! s:encode(data) abort
  return s:encodebytes(s:ByteArray.from_string(a:data))
endfunction

function! s:encodebin(data) abort
  return s:encodebytes(s:ByteArray.from_hexstring(a:data))
endfunction

function! s:encodebytes(data) abort
  return s:Base32util.b32encode(a:data,
        \ s:crockford_encode_table,
        \ s:is_padding,
        \ s:padding_symbol)
endfunction

function! s:decode(data) abort
  return s:ByteArray.to_string(s:decoderaw(a:data))
endfunction

function! s:decoderaw(data) abort
  let data = toupper(a:data) " case insensitive
  return s:Base32util.b32decode(filter(split(a:data, '\zs'), {idx, c -> !s:is_ignore_symbol(c)}),
        \ s:crockford_decode_map,
        \ s:is_padding,
        \ s:is_padding_symbol)
endfunction

let s:is_padding = 0
let s:padding_symbol = ''
let s:is_padding_symbol = {c -> 0}
let s:is_ignore_symbol = {c -> c == '-'}

" Value Encode Digit Decode Digit
"     0            0            0 o O
"     1            1            1 i I l L
"     2            2            2
"     3            3            3
"     4            4            4
"     5            5            5
"     6            6            6
"     7            7            7
"     8            8            8
"     9            9            9
"    10            A            a A
"    11            B            b B
"    12            C            c C
"    13            D            d D
"    14            E            e E
"    15            F            f F
"    16            G            g G
"    17            H            h H
"    18            J            j J
"    19            K            k K
"    20            M            m M
"    21            N            n N
"    22            P            p P
"    23            Q            q Q
"    24            R            r R
"    25            S            s S
"    26            T            t T
"    27            V            v V
"    28            W            w W
"    29            X            x X
"    30            Y            y Y
"    31            Z            z Z

let s:crockford_encode_table = [
      \ '0', '1', '2', '3', '4', '5', '6', '7',
      \ '8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
      \ 'G', 'H', 'J', 'K', 'M', 'N', 'P', 'Q',
      \ 'R', 'S', 'T', 'V', 'W', 'X', 'Y', 'Z']

let s:crockford_decode_map = {
      \ '0' :  0,  'o' :  0,  'O' :  0,
      \ '1' :  1,  'i' :  1,  'I' :  1,  'l' :  1,  'L' :  1,
      \ '2' :  2,
      \ '3' :  3,
      \ '4' :  4,
      \ '5' :  5,
      \ '6' :  6,
      \ '7' :  7,
      \ '8' :  8,
      \ '9' :  9,
      \ 'a' : 10,  'A' : 10,
      \ 'b' : 11,  'B' : 11,
      \ 'c' : 12,  'C' : 12,
      \ 'd' : 13,  'D' : 13,
      \ 'e' : 14,  'E' : 14,
      \ 'f' : 15,  'F' : 15,
      \ 'g' : 16,  'G' : 16,
      \ 'h' : 17,  'H' : 17,
      \ 'j' : 18,  'J' : 18,
      \ 'k' : 19,  'K' : 19,
      \ 'm' : 20,  'M' : 20,
      \ 'n' : 21,  'N' : 21,
      \ 'p' : 22,  'P' : 22,
      \ 'q' : 23,  'Q' : 23,
      \ 'r' : 24,  'R' : 24,
      \ 's' : 25,  'S' : 25,
      \ 't' : 26,  'T' : 26,
      \ 'v' : 27,  'V' : 27,
      \ 'w' : 28,  'W' : 28,
      \ 'x' : 29,  'X' : 29,
      \ 'y' : 30,  'Y' : 30,
      \ 'z' : 31,  'Z' : 31,
      \ }

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
