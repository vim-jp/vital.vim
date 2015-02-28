
scriptencoding utf-8

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Bitwise = s:V.import('Bitwise')
endfunction

function! s:_char2binary(c) abort
  " echo s:_char2binary('c')
  " [0,1,1,0 ,0,0,1,1]
  let bits = [0,0,0,0 ,0,0,0,0]
  if len(a:c) is 1
    let n = 1
    for i in range(7,0,-1)
      let bits[i] = s:Bitwise.and(char2nr(a:c),n) != 0
      let n = n * 2
    endfor
  else
  endif
  return bits
endfunction
function! s:_count_1_prefixed(bits) abort
  " echo s:_count_1_prefixed([1,1,0,0 ,0,0,1,1])
  " 2
  let c = 0
  for b in a:bits
    if b is 0
      break
    else
      let c = c + 1
    endif
  endfor
  return c
endfunction
function! s:_set_encoding() abort
  set encoding=utf-8
endfunction

function! s:is_utf8(line) abort
  " http://tools.ietf.org/html/rfc3629
  let saved_encoding = &encoding
  call s:_set_encoding()

  let cs = a:line
  let i = 0
  while i < len(cs)
    let bits = s:_char2binary(cs[i])
    let c = s:_count_1_prefixed(bits)

    " 1 byte utf-8 char. this is asci char.
    if c is 0
      let i += 1

      " 2~4 byte utf-8 char.
    elseif 2 <= c && c <= 4
      let i += 1
      " consume b10...
      for _ in range(1,c-1)
        let bits = s:_char2binary(cs[i])
        let c = s:_count_1_prefixed(bits)
        if c is 1
          " ok
        else
          " not utf-8
          let &encoding = saved_encoding
          return 0
        endif
        let i += 1
      endfor
    else
      " not utf-8
      let &encoding = saved_encoding
      return 0
    endif
  endwhile
  let &encoding = saved_encoding
  return 1
endfunction
function! s:is_eucjp(line) abort
  " http://charset.7jp.net/euc.html
  let saved_encoding = &encoding
  call s:_set_encoding()

  let cs = a:line
  let i = 0
  while i < len(cs)
    if 0x00 <= char2nr(cs[i]) && char2nr(cs[i]) <= 0x7f
      let i += 1
    elseif 0xa1 <= char2nr(cs[i]) && char2nr(cs[i]) <= 0xfe
      let i += 1
      if 0xa1 <= char2nr(cs[i]) && char2nr(cs[i]) <= 0xfe
        let i += 1
      else
        let &encoding = saved_encoding
        return 0
      endif
    elseif 0x8e is char2nr(cs[i])
      let i += 1
      if 0xa1 <= char2nr(cs[i]) && char2nr(cs[i]) <= 0xdf
        let i += 1
      else
        let &encoding = saved_encoding
        return 0
      endif
    else
      let &encoding = saved_encoding
      return 0
    endif
  endwhile
  let &encoding = saved_encoding
  return 1
endfunction
function! s:is_cp932(line) abort
  " http://charset.7jp.net/sjis.html
  let saved_encoding = &encoding
  call s:_set_encoding()

  let cs = a:line
  let i = 0
  while i < len(cs)
    if 0x00 <= char2nr(cs[i]) && char2nr(cs[i]) <= 0x7f
      let i += 1
    elseif 0xa1 <= char2nr(cs[i]) && char2nr(cs[i]) <= 0xdf
      let i += 1

    elseif (0x81 <= char2nr(cs[i]) && char2nr(cs[i]) <= 0x9f)
    \ || (0xe0 <= char2nr(cs[i]) && char2nr(cs[i]) <= 0xef)
      let i += 1
      if     (0x40 <= char2nr(cs[i]) && char2nr(cs[i]) <= 0x7e)
      \ || (0x80 <= char2nr(cs[i]) && char2nr(cs[i]) <= 0xfc)
        let i += 1
      else
        let &encoding = saved_encoding
        return 0
      endif
    elseif 0x8e is char2nr(cs[i])
      let i += 1
      if 0xa1 <= char2nr(cs[i]) && char2nr(cs[i]) <= 0xdf
        let i += 1
      else
        let &encoding = saved_encoding
        return 0
      endif
    else
      let &encoding = saved_encoding
      return 0
    endif
  endwhile
  let &encoding = saved_encoding
  return 1
endfunction
function! s:is_iso2022jp(line) abort
  " http://charset.7jp.net/jis.html
  let saved_encoding = &encoding
  call s:_set_encoding()

  let cs = a:line
  let mode = "MODE_A"
  let i = 0
  while i < len(cs)
    if 0x1b is char2nr(cs[i]) && 0x24 is char2nr(cs[i+1])  && 0x40 is char2nr(cs[i+2])
      let i += 3
      let mode = "MODE_B"
    elseif 0x1b is char2nr(cs[i]) && 0x24 is char2nr(cs[i+1])  && 0x42 is char2nr(cs[i+2])
      let i += 3
      let mode = "MODE_C"
    elseif 0x1b is char2nr(cs[i]) && 0x26 is char2nr(cs[i+1])  && 0x40 is char2nr(cs[i+2])
    \ && 0x1b is char2nr(cs[i+3]) && 0x24 is char2nr(cs[i+4])  && 0x42 is char2nr(cs[i+5])
      let i += 6
      let mode = "MODE_D"
    elseif 0x1b is char2nr(cs[i]) && 0x28 is char2nr(cs[i+1])  && 0x42 is char2nr(cs[i+2])
      let i += 3
      let mode = "MODE_A"
      "elseif 0x1b is char2nr(cs[i]) && 0x28 is char2nr(cs[i+1])  && 0x4a is char2nr(cs[i+2])
      "  let i += 3
      "  let mode = "MODE_E"
    elseif 0x1b is char2nr(cs[i]) && 0x28 is char2nr(cs[i+1])  && 0x49 is char2nr(cs[i+2])
      let i += 3
      let mode = "MODE_F"

    elseif mode =~ "MODE_A"
      if 0x00 <= char2nr(cs[i]) && char2nr(cs[i]) <= 0x7f
        let i += 1
      else
        let &encoding = saved_encoding
        return 0
      endif
    elseif mode =~ "MODE_F"
      if   (0x21 <= char2nr(cs[i]) && char2nr(cs[i]) <= 0x5f)
      \ || (0xa1 <= char2nr(cs[i]) && char2nr(cs[i]) <= 0xdf)
        let i += 1
      else
        let &encoding = saved_encoding
        return 0
      endif
    elseif mode =~ "MODE_B" || mode =~ "MODE_C" || mode =~ "MODE_D"
      if   (0x21 <= char2nr(cs[i]) && char2nr(cs[i]) <= 0x7e)
      \ && (0x21 <= char2nr(cs[i+1]) && char2nr(cs[i+1]) <= 0x7e)
        let i += 2
      else
        let &encoding = saved_encoding
        return 0
      endif
    else
      let &encoding = saved_encoding
      return 0
    endif
  endwhile
  let &encoding = saved_encoding
  return 1
endfunction
function! s:of(str) abort
  if s:is_iso2022jp(a:str)
    return "iso-2022-jp"
  elseif s:is_utf8(a:str)
    return "utf-8"
  elseif s:is_eucjp(a:str)
    return "euc-jp"
  elseif s:is_cp932(a:str)
    return "cp932"
  else
    throw "vital: CharsetDetector: Unknown charcode of " . a:str
  endif
endfunction
function! s:iconv(lines,...) abort
  let to_encode = a:0 > 0 ? a:1 : &encoding
  let lines = type(a:lines) is type([]) ? copy(a:lines) : [(a:lines)]
  let encoded_lines = map(lines, 'iconv(v:val, s:of(v:val), to_encode)')
  let lines_str = join(encoded_lines, "\n")
  let lines_str = substitute(lines_str, "\r\n", "\r", "g")
  let lines_str = substitute(lines_str, "\n", "\r", "g")
  return split(lines_str, "\r")
endfunction

