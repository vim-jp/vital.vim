" Utilities for List for Byte data.

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Bitwise = s:V.import('Bitwise')
  let s:Type    = s:V.import('Vim.Type')
  let s:List    = s:V.import('Data.List')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise', 'Vim.Type', 'Data.List']
endfunction

function! s:validate(data) abort
  return type(a:data) == s:Type.types.list
        \ && len(a:data) == len(s:List.filter(a:data, { v -> type(v) == s:Type.types.number }))
        \ && min(a:data) >= 0
        \ && max(a:data) <= 255
endfunction

function! s:from_blob(blob) abort
  if exists('*blob2list')  " add 8.2.3438
    return blob2list(a:blob)
  else
    return s:List.new(len(a:blob), {i -> a:blob[i]})
  endif
endfunction

function! s:to_blob(bytes) abort
  if exists('*list2blob')  " add 8.2.3438
    return list2blob(a:bytes)
  else
    return eval('0z' . s:to_hexstring(a:bytes))
  endif
endfunction

function! s:from_string(str) abort
  return s:List.new(len(a:str), {i -> char2nr(a:str[i])})
endfunction

function! s:to_string(bytes) abort
  return eval('"' . join(map(copy(a:bytes), 'printf(''\x%02x'', v:val)'), '') . '"')
endfunction

function! s:from_hexstring(hexstr) abort
  return s:List.new(len(a:hexstr)/2, {i -> str2nr(a:hexstr[i*2 : i*2+1], 16)})
endfunction

function! s:to_hexstring(bytes) abort
  return join(map(copy(a:bytes), 'printf(''%02x'', v:val)'), '')
endfunction

function! s:from_int(value, bits) abort
  " return to big endian
  return s:List.new(a:bits/8, {i -> s:Bitwise.uint8(s:Bitwise.rshift(a:value, a:bits - (i + 1)*8))})
endfunction

function! s:to_int(bytes) abort
  " from big endian
  let ret = 0
  let maxlen = len(a:bytes)
  let values = map(copy(a:bytes), { i,v ->  s:Bitwise.lshift(v, (maxlen-1 - i) * 8)})
  for v in values
    let ret = s:Bitwise.or(v,ret)
  endfor
  return ret
endfunction

function! s:endian_convert(bytes) abort
  if !(len(a:bytes) > 1)
    call s:_throw('data count need 2 or more')
  endif
  if (len(a:bytes) % 2)
    call s:_throw('odd data count')
  endif
  return reverse(copy(a:bytes))
endfunction

" inner

function! s:_throw(message) abort
  throw 'vital: Data.List.Byte: ' . a:message
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
