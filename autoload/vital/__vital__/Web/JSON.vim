let s:save_cpo = &cpo
set cpo&vim

let s:control_chars = {
    \   '\': '\\',
    \   '"': '\"',
    \   "\x01": '\u0001',
    \   "\x02": '\u0002',
    \   "\x03": '\u0003',
    \   "\x04": '\u0004',
    \   "\x05": '\u0005',
    \   "\x06": '\u0006',
    \   "\x07": '\u0007',
    \   "\x08": '\b',
    \   "\x09": '\t',
    \   "\x0a": '\n',
    \   "\x0b": '\u000b',
    \   "\x0c": '\f',
    \   "\x0d": '\r',
    \   "\x0e": '\u000e',
    \   "\x0f": '\u000f',
    \   "\x10": '\u0010',
    \   "\x11": '\u0011',
    \   "\x12": '\u0012',
    \   "\x13": '\u0013',
    \   "\x14": '\u0014',
    \   "\x15": '\u0015',
    \   "\x16": '\u0016',
    \   "\x17": '\u0017',
    \   "\x18": '\u0018',
    \   "\x19": '\u0019',
    \   "\x1a": '\u001a',
    \   "\x1b": '\u001b',
    \   "\x1c": '\u001c',
    \   "\x1d": '\u001d',
    \   "\x1e": '\u001e',
    \   "\x1f": '\u001f',
    \ }
lockvar s:control_chars

let s:float_constants = {
    \   'nan': 'NaN',
    \   '-nan': 'NaN',
    \   'inf': 'Infinity',
    \   '-inf': '-Infinity',
    \ }
let s:float_nan = 0.0 / 0
let s:float_inf = 1.0 / 0
lockvar s:float_constants s:float_nan s:float_inf

let s:special_constants = {
    \   'v:true': 'true',
    \   'v:false': 'false',
    \   'v:null': 'null',
    \   'v:none': 'null',
    \ }
lockvar s:special_constants

function! s:_true() abort
  return v:true
endfunction

function! s:_false() abort
  return v:false
endfunction

function! s:_null() abort
  return v:null
endfunction

function! s:_resolve(val, prefix) abort
  let t = type(a:val)
  if t == type('')
    let m = matchlist(a:val, '^' . a:prefix . '\(null\|true\|false\)$')
    if !empty(m)
      return s:const[m[1]]
    endif
  elseif t == type([]) || t == type({})
    return map(a:val, 's:_resolve(v:val, a:prefix)')
  endif
  return a:val
endfunction

function! s:_vital_created(module) abort
  " define constant variables
  if !exists('s:const')
    let s:const = {}
    let s:const.true = function('s:_true')
    let s:const.false = function('s:_false')
    let s:const.null = function('s:_null')
    lockvar s:const
  endif
  call extend(a:module, s:const)
endfunction

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:string = s:V.import('Data.String')
endfunction

function! s:_vital_depends() abort
  return ['Data.String']
endfunction

" @vimlint(EVL102, 1, l:null)
" @vimlint(EVL102, 1, l:true)
" @vimlint(EVL102, 1, l:false)
" @vimlint(EVL102, 1, l:NaN)
" @vimlint(EVL102, 1, l:Infinity)
function! s:decode(json, ...) abort
  let settings = extend({
        \ 'use_token': 0,
        \ 'allow_nan': 1,
        \}, get(a:000, 0, {}))
  let json = iconv(a:json, 'utf-8', &encoding)
  let json = join(split(json, "\n"), '')
  let json = substitute(json, '\\u34;', '\\"', 'g')
  let json = substitute(json, '\\u\(\x\x\x\x\)', '\=s:string.nr2enc_char("0x".submatch(1))', 'g')
  " convert surrogate pair
  let json = substitute(json, '\([\uD800-\uDBFF]\)\([\uDC00-\uDFFF]\)',
        \ '\=nr2char(0x10000+and(0x7ff,char2nr(submatch(1)))*0x400+and(0x3ff,char2nr(submatch(2))))',
        \ 'g')
  if settings.allow_nan
    let [NaN,Infinity] = [s:float_nan,s:float_inf]
  endif
  if settings.use_token
    let prefix = '__Web.JSON__'
    while stridx(json, prefix) != -1
      let prefix .= '_'
    endwhile
    let [null,true,false] = map(['null','true','false'], 'prefix . v:val')
    sandbox return s:_resolve(eval(json), prefix)
  else
    let [null,true,false] = [s:const.null(),s:const.true(),s:const.false()]
    sandbox return eval(json)
  endif
endfunction
" @vimlint(EVL102, 0, l:null)
" @vimlint(EVL102, 0, l:true)
" @vimlint(EVL102, 0, l:false)
" @vimlint(EVL102, 0, l:NaN)
" @vimlint(EVL102, 0, l:Infinity)

function! s:encode(val, ...) abort
  let settings = extend({
        \ 'indent': 0,
        \ 'allow_nan': 1,
        \ 'from_encoding': &encoding,
        \ 'ensure_ascii': 0,
        \}, get(a:000, 0, {})
        \)
  let json = s:_encode(a:val, settings)
  if settings.ensure_ascii
    let json = substitute(json, '[\U0000007f-\U0010ffff]',
        \ {m -> s:_escape_unicode_chars(m[0])}, 'g')
  endif
  return json
endfunction

function! s:_escape_unicode_chars(char) abort
  let n = char2nr(a:char)
  if n < 0x10000
    return printf('\u%04x', n)
  else
    let n -= 0x10000
    return printf('\u%04x%\u%04x', 0xd800 + n / 0x400, 0xdc00 + and(0x3ff, n))
  endif
endfunction

function! s:_encode(val, settings) abort
  let t = type(a:val)
  if t == 0
    return a:val
  elseif t == 1
    let s = iconv(a:val, a:settings.from_encoding, 'utf-8')
    let s = substitute(s, '[\x01-\x1f\\"]', '\=s:control_chars[submatch(0)]', 'g')
    return '"' . s . '"'
  elseif t == 2
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
  elseif t == 3
    return s:_encode_list(a:val, a:settings)
  elseif t == 4
    return s:_encode_dict(a:val, a:settings)
  elseif t == 5
    let val = string(a:val)
    if a:settings.allow_nan
      let val = get(s:float_constants, val, val)
    elseif has_key(s:float_constants, val)
      throw 'vital: Web.JSON: Invalid float value: ' . val
    endif
    return val
  elseif t == 6 || t == 7
    return get(s:special_constants, a:val)
  else
    return string(a:val)
  endif
endfunction

" @vimlint(EVL102, 1, l:ns)
function! s:_encode_list(val, settings) abort
  if empty(a:val)
    return '[]'
  elseif !a:settings.indent
    let encoded_candidates = map(copy(a:val), 's:_encode(v:val, a:settings)')
    return printf('[%s]', join(encoded_candidates, ','))
  else
    let previous_indent = get(a:settings, '_previous_indent')
    let indent = previous_indent + a:settings.indent
    let ns = extend(copy(a:settings), {
          \ '_previous_indent': indent,
          \})
    let encoded_candidates = map(
          \ copy(a:val),
          \ printf('''%s'' . s:_encode(v:val, ns)', repeat(' ', indent)),
          \)
    return printf(
          \ "[\n%s\n%s]",
          \ join(encoded_candidates, ",\n"),
          \ repeat(' ', previous_indent)
          \)
  endif
endfunction
" @vimlint(EVL102, 0, l:ns)

" @vimlint(EVL102, 1, l:ns)
function! s:_encode_dict(val, settings) abort
  if empty(a:val)
    return '{}'
  elseif !a:settings.indent
    let encoded_candidates = map(keys(a:val),
          \ 's:_encode(v:val, a:settings) . '':'' . s:_encode(a:val[v:val], a:settings)'
          \)
    return printf('{%s}', join(encoded_candidates, ','))
  else
    let previous_indent = get(a:settings, '_previous_indent')
    let indent = previous_indent + a:settings.indent
    let ns = extend(copy(a:settings), {
          \ '_previous_indent': indent,
          \})
    let encoded_candidates = map(keys(a:val),
          \ printf(
          \   '''%s'' . s:_encode(v:val, ns) . '': '' . s:_encode(a:val[v:val], ns)',
          \   repeat(' ', indent),
          \ ),
          \)
    return printf("{\n%s\n%s}",
          \ join(encoded_candidates, ",\n"),
          \ repeat(' ', previous_indent),
          \)
  endif
endfunction
" @vimlint(EVL102, 0, l:ns)

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
