" Utilities for Base32.
" RFC 4648 http://tools.ietf.org/html/rfc4648.html

let s:save_cpo = &cpo
set cpo&vim

function! s:encode(data) abort
  let b32 = s:_b32encode(s:_str2bytes(a:data), s:standard_table, '=')
  return join(b32, '')
endfunction

function! s:encodebin(data) abort
  let b32 = s:_b32encode(s:_binstr2bytes(a:data), s:standard_table, '=')
  return join(b32, '')
endfunction

function! s:decode(data) abort
  let data = toupper(a:data) " case insensitive
  let bytes = s:_b32decode(split(data, '\zs'), s:standard_table, '=')
  return s:_bytes2str(bytes)
endfunction

let s:standard_table = [
      \ 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
      \ 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
      \ 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
      \ 'Y', 'Z', '2', '3', '4', '5', '6', '7' ]

function! s:_b32encode(bytes, table, pad) abort
  let b32 = []
  for i in range(0, len(a:bytes) - 1, 5)
    if 5 <= ((len(a:bytes) - 1) - i)
      let n = a:bytes[i]               * 0x100000000
            \ + get(a:bytes, i + 1, 0) *   0x1000000
            \ + get(a:bytes, i + 2, 0) *     0x10000
            \ + get(a:bytes, i + 3, 0) *       0x100
            \ + get(a:bytes, i + 4, 0)
      let bitstring = printf('%040b',n)
    else
      let length = len(a:bytes) - i
      let n = a:bytes[i]
      for x in range(i + 1,(len(a:bytes) - 1))
        let n = (n * 0x100) + a:bytes[x]
      endfor
      let bitstring = printf('%0'. string(length*8) .'b',n)
      let zerocount = 5 - (len(bitstring) % 5)
      if 5 != zerocount
        for x in range(0, zerocount-1)
          let bitstring = bitstring . '0'
        endfor
      endif
    endif
    for fivebit in split(bitstring, '.....\zs')
      call execute('let fivebitnum = 0b' . fivebit)
      call add(b32, a:table[fivebitnum])
    endfor
  endfor
  if 0 != len(b32) % 8
    let padlen = 8 - (len(b32) % 8)
    for i in range(0, padlen - 1)
      call add(b32, a:pad)
    endfor
  endif
  return b32
endfunction

function! s:_b32decode(b32, table, pad) abort
  let a2i = {}
  for i in range(len(a:table))
    let a2i[a:table[i]] = i
  endfor
  let bytes = []
  for i in range(0, (len(a:b32) - 1), 8)
    let n = a2i[a:b32[i]]                                     * 0x800000000
          \ + a2i[a:b32[i + 1]]                               *  0x40000000
          \ + (a:b32[i + 2] == a:pad ? 0 : a2i[a:b32[i + 2]]) *   0x2000000
          \ + (a:b32[i + 3] == a:pad ? 0 : a2i[a:b32[i + 3]]) *    0x100000
          \ + (a:b32[i + 4] == a:pad ? 0 : a2i[a:b32[i + 4]]) *      0x8000
          \ + (a:b32[i + 5] == a:pad ? 0 : a2i[a:b32[i + 5]]) *       0x400
          \ + (a:b32[i + 6] == a:pad ? 0 : a2i[a:b32[i + 6]]) *        0x20
          \ + (a:b32[i + 7] == a:pad ? 0 : a2i[a:b32[i + 7]])
    call add(bytes, n / 0x100000000        )
    call add(bytes, n /   0x1000000 % 0x100)
    call add(bytes, n /     0x10000 % 0x100)
    call add(bytes, n /       0x100 % 0x100)
    call add(bytes, n               % 0x100)
  endfor
  if a:b32[-1] == a:pad
    unlet bytes[-1]
  endif
  if a:b32[-3] == a:pad
    unlet bytes[-1]
  endif
  if a:b32[-4] == a:pad
    unlet bytes[-1]
  endif
  if a:b32[-6] == a:pad
    unlet bytes[-1]
  endif
  return bytes
endfunction

function! s:_binstr2bytes(str) abort
  return map(range(len(a:str)/2), 'eval("0x".a:str[v:val*2 : v:val*2+1])')
endfunction

function! s:_str2bytes(str) abort
  return map(range(len(a:str)), 'char2nr(a:str[v:val])')
endfunction

function! s:_bytes2str(bytes) abort
  return eval('"' . join(map(copy(a:bytes), 'printf(''\x%02x'', v:val)'), '') . '"')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
