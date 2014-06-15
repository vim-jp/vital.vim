let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V)
  let s:V = a:V
  let s:string = s:V.import('Data.String')
endfunction

function! s:_vital_depends()
  return ['Data.String']
endfunction

function! s:_true()
  return 1
endfunction

function! s:_false()
  return 0
endfunction

function! s:_null()
  return 0
endfunction

function! s:token(kind)
  " Note: (by Alisue)
  "
  "   I would like to use these tokens like
  "
  "     let s:JSON = s:V.import('Web.JSON')
  "     echo s:JSON.encode(s:JSON.true)
  "
  "   But vital.vim seems not supporting constant variables
  "   in the vital modules.
  "
  if a:kind == 'true'
    return function('s:_true')
  elseif a:kind == 'false'
    return function('s:_false')
  elseif a:kind == 'null'
    return function('s:_null')
  else
    throw 'unknown token kind was specified'
  endif
endfunction

function! s:decode(json)
  let json = iconv(a:json, "utf-8", &encoding)
  let json = substitute(json, '\n', '', 'g')
  let json = substitute(json, '\\u34;', '\\"', 'g')
  let json = substitute(json, '\\u\(\x\x\x\x\)', '\=s:string.nr2enc_char("0x".submatch(1))', 'g')
  let [null,true,false] = [0,1,0]
  sandbox let ret = eval(json)
  return ret
endfunction

function! s:encode(val)
  if type(a:val) == 0
    return a:val
  elseif type(a:val) == 1
    let json = '"' . escape(a:val, '\"') . '"'
    let json = substitute(json, "\r", '\\r', 'g')
    let json = substitute(json, "\n", '\\n', 'g')
    let json = substitute(json, "\t", '\\t', 'g')
    return iconv(json, &encoding, "utf-8")
  elseif type(a:val) == 2
    if function('s:_true') == a:val
      return 'true'
    elseif function('s:_false') == a:val
      return 'false'
    elseif function('s:_null') == a:val
      return 'null'
    else
      " backward compatibility
      return string(a:val)
    endif
  elseif type(a:val) == 3
    return '[' . join(map(copy(a:val), 's:encode(v:val)'), ',') . ']'
  elseif type(a:val) == 4
    return '{' . join(map(keys(a:val), 's:encode(v:val).":".s:encode(a:val[v:val])'), ',') . '}'
  else
    return string(a:val)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
