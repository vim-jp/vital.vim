" bitwise operators
" moved from github.com/ynkdir/vim-funlib

let s:save_cpo = &cpo
set cpo&vim

" inner utility

let s:bits = has('num64') ? 64 : 32
let s:mask = s:bits - 1
let s:mask32 = 32 - 1

let s:pow2 = [1]
for s:i in range(s:mask)
  call add(s:pow2, s:pow2[-1] * 2)
endfor
unlet s:i

let s:min = s:pow2[-1]

" 32bit/64bit common method
function! s:_throw(msg) abort
  throw 'vital: Bitwise: ' . a:msg
endfunction

" compare as unsigned int
function! s:compare(a, b) abort
  if (a:a >= 0 && a:b >= 0) || (a:a < 0 && a:b < 0)
    return a:a < a:b ? -1 : a:a > a:b ? 1 : 0
  else
    return a:a < 0 ? 1 : -1
  endif
endfunction

function! s:lshift(a, n) abort
  " and/or/xor/invert generate from built-in
  " vint: -ProhibitUsingUndeclaredVariable
  return a:a * s:pow2[s:and(a:n, s:mask)]
  " vint: +ProhibitUsingUndeclaredVariable
endfunction

function! s:rshift(a, n) abort
  " and/or/xor/invert generate from built-in
  " vint: -ProhibitUsingUndeclaredVariable
  let n = s:and(a:n, s:mask)
  " vint: +ProhibitUsingUndeclaredVariable
  return n == 0 ? a:a :
  \  a:a < 0 ? (a:a - s:min) / s:pow2[n] + s:pow2[-2] / s:pow2[n - 1]
  \          : a:a / s:pow2[n]
endfunction

" 32bit or 64bit specific method
" define sign_extension
"        lshift32/rshift32 64bit only implementation.
if has('num64')
  " NOTE:
  " An int literal larger than or equal to 0x8000000000000000 will be rounded
  " to 0x7FFFFFFFFFFFFFFF after Vim 8.0.0219, so create it without literal
  let s:xFFFFFFFF00000000 = has('patch-8.0.0219')
        \ ? 0xFFFFFFFF * s:pow2[and(32, s:mask)]
        \ : 0xFFFFFFFF00000000
  function! s:sign_extension(n) abort
    if and(a:n, 0x80000000)
      return or(a:n, s:xFFFFFFFF00000000)
    else
      return and(a:n, 0xFFFFFFFF)
    endif
  endfunction
  function! s:lshift32(a, n) abort
    return and(s:lshift(a:a, and(a:n, s:mask32)), 0xFFFFFFFF)
  endfunction
  function! s:rshift32(a, n) abort
    return s:rshift(and(a:a, 0xFFFFFFFF), and(a:n, s:mask32))
  endfunction
else
  function! s:sign_extension(n) abort
    return a:n
  endfunction
endif

" 32bit or 64bit specific method
" builtin and funcref setup at module creation time.
" define and/or/xor/invert built-in
"        lshift32/rshift32 32bit only altnative define.
function! s:_vital_created(module) abort
  for op in ['and', 'or', 'xor', 'invert']
    let a:module[op] = function(op)
    let s:[op] = a:module[op]
  endfor
  if !has('num64')
    let a:module.lshift32 = a:module.lshift
    let a:module.rshift32 = a:module.rshift
  endif
endfunction

" setup at module loaded time.
" define inner utility part2 : use defined method
function! s:_vital_loaded(V) abort
  if has('num64')
    let s:mask32bit = 0xFFFFFFFF
    " and/or/xor/invert generate from built-in
    " vint: -ProhibitUsingUndeclaredVariable
    let s:mask64bit = s:or(
          \ s:lshift(s:mask32bit, 32),
          \          s:mask32bit
          \)
    " vint: +ProhibitUsingUndeclaredVariable
  else
    " vint: -ProhibitUsingUndeclaredVariable
    let s:mask32bit = s:or(
          \ s:lshift(0xFFFF, 16),
          \          0xFFFF
          \)
    " vint: +ProhibitUsingUndeclaredVariable
  endif
endfunction

" 32bit/64bit common method part2 : use defined method

function! s:uint8(value) abort
  " and/or/xor/invert generate from built-in
  " vint: -ProhibitUsingUndeclaredVariable
  return s:and(a:value, 0xFF)
  " vint: +ProhibitUsingUndeclaredVariable
endfunction

function! s:uint16(value) abort
  " and/or/xor/invert generate from built-in
  " vint: -ProhibitUsingUndeclaredVariable
  return s:and(a:value, 0xFFFF)
  " vint: +ProhibitUsingUndeclaredVariable
endfunction

function! s:uint32(value) abort
  " and/or/xor/invert generate from built-in
  " vint: -ProhibitUsingUndeclaredVariable
  return s:and(a:value, s:mask32bit)
  " vint: +ProhibitUsingUndeclaredVariable
endfunction

function! s:rotate8l(data, bits) abort
  let data = s:uint8(a:data)
  " and/or/xor/invert generate from built-in
  " vint: -ProhibitUsingUndeclaredVariable
  return s:uint8(s:or(s:lshift(data, a:bits),
                    \ s:rshift(data, 8 - a:bits)))
  " vint: +ProhibitUsingUndeclaredVariable
endfunction
function! s:rotate8r(data, bits) abort
  return s:rotate8l(a:data, 8 - a:bits)
endfunction

function! s:rotate16l(data, bits) abort
  let data = s:uint16(a:data)
  " and/or/xor/invert generate from built-in
  " vint: -ProhibitUsingUndeclaredVariable
  return s:uint16(s:or(s:lshift(data, a:bits),
                     \ s:rshift(data, 16 - a:bits)))
  " vint: +ProhibitUsingUndeclaredVariable
endfunction
function! s:rotate16r(data, bits) abort
  return s:rotate16l(a:data, 16 - a:bits)
endfunction

function! s:rotate32l(data, bits) abort
  let data = s:uint32(a:data)
  " and/or/xor/invert generate from built-in
  " vint: -ProhibitUsingUndeclaredVariable
  return s:uint32(s:or(s:lshift(data, a:bits),
                     \ s:rshift(data, 32 - a:bits)))
  " vint: +ProhibitUsingUndeclaredVariable
endfunction
function! s:rotate32r(data, bits) abort
  return s:rotate32l(a:data, 32 - a:bits)
endfunction

" 32bit or 64bit specific method part2 : use defined method
" define  uint64/rotate64l 64bit only implementation.
"                          32bit throw exception.
if has('num64')
  function! s:uint64(value) abort
    " and/or/xor/invert generate from built-in
    " vint: -ProhibitUsingUndeclaredVariable
    return s:and(a:value, s:mask64bit)
    " vint: +ProhibitUsingUndeclaredVariable
  endfunction

  function! s:rotate64l(data, bits) abort
    let data = s:uint64(a:data)
    " and/or/xor/invert generate from built-in
    " vint: -ProhibitUsingUndeclaredVariable
    return s:uint64(s:or(s:lshift(data, a:bits),
                       \ s:rshift(data, 64 - a:bits)))
    " vint: +ProhibitUsingUndeclaredVariable
  endfunction
else
  function! s:uint64(value) abort
    call s:_throw('64bit unsupport.')
  endfunction

  function! s:rotate64l(data, bits) abort
    call s:_throw('64bit unsupport.')
  endfunction
endif

" When 32bit throw exception.
function! s:rotate64r(data, bits) abort
  return s:rotate64l(a:data, 64 - a:bits)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
