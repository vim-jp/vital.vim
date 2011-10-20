let s:__save_cpo = &cpo
set cpo&vim

function! s:__nr2byte(nr)
  if a:nr < 0x80
    return nr2char(a:nr)
  elseif a:nr < 0x800
    return nr2char(a:nr/64+192).nr2char(a:nr%64+128)
  else
    return nr2char(a:nr/4096%16+224).nr2char(a:nr/64%64+128).nr2char(a:nr%64+128)
  endif
endfunction

function! s:__nr2enc_char(charcode)
  if &encoding == 'utf-8'
    return nr2char(a:charcode)
  endif
  let char = s:__nr2byte(a:charcode)
  if strlen(char) > 1
    let char = strtrans(iconv(char, 'utf-8', &encoding))
  endif
  return char
endfunction

function! s:decode(json)
  let json = iconv(a:json, "utf-8", &encoding)
  let json = substitute(json, '\n', '', 'g')
  let json = substitute(json, '\\u34;', '\\"', 'g')
  let json = substitute(json, '\\u\(\x\x\x\x\)', '\=s:__nr2enc_char("0x".submatch(1))', 'g')
  let [null,true,false] = [0,1,0]
  return eval(json)
endfunction

function! s:encode(obj)
  let json = string(a:obj)
  if type(a:obj) == 1
    let json = ''''.substitute(json[1:-2], '''''', '\\''', 'g').''''
  else
    let json = substitute(json, '''''', '\\''', 'g')
  endif
  let json = substitute(json, "\r", '\\r', 'g')
  let json = substitute(json, "\n", '\\n', 'g')
  let json = substitute(json, "\t", '\\t', 'g')
  let json = iconv(json, &encoding, "utf-8")
  return json
endfunction

let &cpo = s:__save_cpo
