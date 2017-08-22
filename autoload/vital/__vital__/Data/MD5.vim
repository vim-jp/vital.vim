" Utilities for MD5.

let s:save_cpo = &cpo
set cpo&vim

let s:bitwise = vital#vital#new().import('Bitwise')
let s:shift = [
      \ 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
      \ 5,  9, 14, 20, 5,  9, 14, 20, 5,  9, 14, 20, 5,  9, 14, 20,
      \ 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
      \ 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
      \ ]

let s:table = [
      \ 0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
      \ 0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
      \ 0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
      \ 0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
      \ 0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
      \ 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
      \ 0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
      \ 0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
      \ 0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
      \ 0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
      \ 0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
      \ 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
      \ 0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
      \ 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
      \ 0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
      \ 0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
      \ ]


function! s:encode(data) abort
  let l:a0 = 0x67452301
  let l:b0 = 0xefcdab89
  let l:c0 = 0x98badcfe
  let l:d0 = 0x10325476

  let l:padded = s:_str2bytes(a:data)
  let l:orig_len = len(l:padded) * 8
  call add(l:padded, 0x80)
  while fmod(len(l:padded), 64) != 56
    call add(l:padded, 0)
  endwhile

  call extend(l:padded, s:_int2bytes(8, l:orig_len))

  for chunk_i in range(0, len(l:padded)-1, 64)
    let l:chunk = l:padded[chunk_i:chunk_i+63]
    let l:M = map(range(16), 's:_bytes2int32(l:chunk[(v:val*4):(v:val*4)+3])')
    let l:A = l:a0
    let l:B = l:b0
    let l:C = l:c0
    let l:D = l:d0

    for l:i in range(64)
      let l:F = 0
      let l:g = 0
      if 0 <= l:i && l:i <= 15
        let l:F = or(and(l:B, l:C), and(invert(l:B), l:D))
        let l:g = l:i
      elseif 16 <= l:i && l:i <= 31
        let l:F = or(and(l:B, l:D), and(invert(l:D), l:C))
        let l:g = fmod((5 * l:i) + 1, 16)
      elseif 32 <= l:i && l:i <= 47
        let l:F = xor(l:B, xor(l:C, l:D))
        let l:g = fmod((3 * l:i) + 5, 16)
      elseif 48 <= l:i  && l:i <= 63
        let l:F = xor(l:C, or(l:B, invert(l:D)))
        let l:g = fmod(7 * l:i, 16)
      endif

      let l:F = l:F + l:A + s:table[l:i] + M[float2nr(l:g)]
      let l:A = l:D
      let l:D = l:C
      let l:C = l:B
      let l:B = l:B + s:_leftrotate(l:F, s:shift[l:i])

    endfor
    let l:a0 = l:a0 + l:A
    let l:b0 = l:b0 + l:B
    let l:c0 = l:c0 + l:C
    let l:d0 = l:d0 + l:D
  endfor

  let l:bytes = []
  call extend(l:bytes, s:_int2bytes(4, l:a0))
  call extend(l:bytes, s:_int2bytes(4, l:b0))
  call extend(l:bytes, s:_int2bytes(4, l:c0))
  call extend(l:bytes, s:_int2bytes(4, l:d0))

  return s:_bytes2str(l:bytes)
endfunction

function! s:_bytes2str(bytes) abort
  return join(map(a:bytes, 'printf(''%02x'', v:val)'), '')
endfunction

function! s:_str2bytes(str) abort
  return map(range(len(a:str)), 'char2nr(a:str[v:val])')
endfunction

function! s:_int2bytes(bits, int) abort
  return map(range(a:bits), 'and(s:bitwise.rshift(a:int, v:val * 8), 0xff)')
endfunction

function! s:_bytes2int32(bytes) abort
  return  or(s:bitwise.lshift(a:bytes[3], 24), 
        \ or(s:bitwise.lshift(a:bytes[2], 16),
        \ or(s:bitwise.lshift(a:bytes[1], 8),
        \ a:bytes[0])))
endfunc

function! s:_leftrotate(x, c) abort
  let l:x = and(a:x, 0xFFFFFFFF)
  return and(or(s:bitwise.lshift(l:x, a:c), s:bitwise.rshift(l:x, (32-a:c))), 0xFFFFFFFF)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
