let s:save_cpo = &cpo
set cpo&vim

let s:utils = V.import('Web.Utils')

function! s:decode(json)
  let json = iconv(a:json, "utf-8", &encoding)
  let json = substitute(json, '\n', '', 'g')
  let json = substitute(json, '\\u34;', '\\"', 'g')
  let json = substitute(json, '\\u\(\x\x\x\x\)', '\=s:utils.nr2enc_char("0x".submatch(1))', 'g')
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

let &cpo = s:save_cpo
