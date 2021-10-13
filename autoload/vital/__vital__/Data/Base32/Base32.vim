" Utilities for Base32.
" RFC 4648 http://tools.ietf.org/html/rfc4648.html

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Bitwise = s:V.import('Bitwise')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise']
endfunction

function! s:b32encode(bytes, table, is_padding, pad) abort
  let b32 = []
  for i in range(0, len(a:bytes) - 1, 5)
    if 5 <= ((len(a:bytes) - 1) - i)
      " @vimlint(EVL108, 1)
      let bitstring = ''
            \ . printf('%08b',     a:bytes[i]        )
            \ . printf('%08b', get(a:bytes, i + 1, 0))
            \ . printf('%08b', get(a:bytes, i + 2, 0))
            \ . printf('%08b', get(a:bytes, i + 3, 0))
            \ . printf('%08b', get(a:bytes, i + 4, 0))
      " @vimlint(EVL108, 0)
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
    call map(split(bitstring, '.....\zs'),'add(b32, a:table[str2nr(v:val, 2)])')
  endfor
  if a:is_padding
    if 0 != len(b32) % 8
      let padlen = 8 - (len(b32) % 8)
      for i in range(0, padlen - 1)
        call add(b32, a:pad)
      endfor
    endif
  endif
  return join(b32, '')
endfunction

function! s:b32decode(b32, map, is_padding, padcheck) abort
  let bytes = []
  if len(a:b32) < 2
    " no data
    return bytes
  endif
  for i in range(0, (len(a:b32) - 1), 8)
    let pack = repeat([0], 8)
    for j in range(8)
      if (len(a:b32) > (i + j)) && !a:padcheck(a:b32[i + j])
        let pack[j] = a:map[a:b32[i + j]]
      endif
    endfor
    "              1         2         3
    "    0123456789012345678901234567890123456789
    "    |------||------||------||------||------|
    "  0 +---+
    "  1      +---+
    "  2           +---+
    "  3                +---+
    "  4                     +---+
    "  5                          +---+
    "  6                               +---+
    "  7                                    +---+
    "
    " high 1byte
    "
    "    01234567
    "    |------|
    "  0 +---+
    "  1      +--
    "
    " low  4byte
    "              1         2         3
    "            89012345678901234567890123456789
    "            |------||------||------||------|
    "  1         -+
    "  2           +---+
    "  3                +---+
    "  4                     +---+
    "  5                          +---+
    "  6                               +---+
    "  7                                    +---+
    "    0b11       -> 0x03
    "    0b11111000 -> 0xf8
    "    0b00000111 -> 0x07
    let n_hi = s:Bitwise.or(
          \ s:Bitwise.and(s:Bitwise.lshift(pack[0], 3), 0xf8),
          \ s:Bitwise.and(s:Bitwise.rshift(pack[1], 2), 0x07)
          \ )

    let n_lo = s:Bitwise.and(pack[1], 0x03) * 0x40000000
          \ + pack[2]                       *  0x2000000
          \ + pack[3]                       *   0x100000
          \ + pack[4]                       *     0x8000
          \ + pack[5]                       *      0x400
          \ + pack[6]                       *       0x20
          \ + pack[7]
    call add(bytes, n_hi                    )
    call add(bytes, n_lo / 0x1000000 % 0x100)
    call add(bytes, n_lo /   0x10000 % 0x100)
    call add(bytes, n_lo /     0x100 % 0x100)
    call add(bytes, n_lo             % 0x100)
    if !a:is_padding && ((len(a:b32) - 1) <  (i + 8))
      " manual nondata byte cut
      let nulldata = (i + 7) - (len(a:b32) - 1)
      if 1 == nulldata
        unlet bytes[-1]
      elseif 3 == nulldata
        unlet bytes[-1]
        unlet bytes[-1]
      elseif 4 == nulldata
        unlet bytes[-1]
        unlet bytes[-1]
        unlet bytes[-1]
      elseif 6 == nulldata
        unlet bytes[-1]
        unlet bytes[-1]
        unlet bytes[-1]
        unlet bytes[-1]
      endif
    endif
  endfor
  if a:is_padding
    if a:padcheck(a:b32[-1])
      unlet bytes[-1]
    endif
    if a:padcheck(a:b32[-3])
      unlet bytes[-1]
    endif
    if a:padcheck(a:b32[-4])
      unlet bytes[-1]
    endif
    if a:padcheck(a:b32[-6])
      unlet bytes[-1]
    endif
  endif
  return bytes
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
