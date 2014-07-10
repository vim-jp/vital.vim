let s:save_cpo = &cpo
set cpo&vim

function! s:_true()
  return 1
endfunction

function! s:_false()
  return 0
endfunction

function! s:_null()
  return 0
endfunction

let s:const = {}
let s:const.true = function('s:_true')
let s:const.false = function('s:_false')
let s:const.null = function('s:_null')


function! s:_vital_loaded(V) dict
  let s:V = a:V
  let s:string = s:V.import('Data.String')
  " define constant variables
  call extend(self, s:const)
endfunction

function! s:_vital_depends()
  return ['Data.String']
endfunction

" @vimlint(EVL102, 1, l:null)
" @vimlint(EVL102, 1, l:true)
" @vimlint(EVL102, 1, l:false)
function! s:decode(json, ...)
  let settings = extend({
        \ 'use_token': 0,
        \}, get(a:000, 0, {}))
  let json = iconv(a:json, "utf-8", &encoding)
  let json = substitute(json, '\n', '', 'g')
  let json = substitute(json, '\\u34;', '\\"', 'g')
  let json = substitute(json, '\\u\(\x\x\x\x\)', '\=s:string.nr2enc_char("0x".submatch(1))', 'g')
  if settings.use_token
    let [null,true,false] = [s:const.null,s:const.true,s:const.false]
  else
    let [null,true,false] = [s:const.null(),s:const.true(),s:const.false()]
  endif
  sandbox let ret = eval(json)
  return ret
endfunction
" @vimlint(EVL102, 0, l:null)
" @vimlint(EVL102, 0, l:true)
" @vimlint(EVL102, 0, l:false)

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
    if s:const.true == a:val
      return 'true'
    elseif s:const.false == a:val
      return 'false'
    elseif s:const.null == a:val
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
