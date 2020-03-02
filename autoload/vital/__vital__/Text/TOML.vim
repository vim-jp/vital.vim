let s:save_cpo = &cpo
set cpo&vim

"
" public api
"
function! s:parse(text) abort
  let input = {
  \   'text': a:text,
  \   'p': 0,
  \   'length': strlen(a:text),
  \}
  return s:_parse(input)
endfunction

function! s:parse_file(filename) abort
  if !filereadable(a:filename)
    throw printf("vital: Text.TOML: No such file `%s'.", a:filename)
  endif

  let text = join(readfile(a:filename), "\n")
  " fileencoding is always utf8
  return s:parse(iconv(text, 'utf8', &encoding))
endfunction

"
" private api
"
" work around: '[^\r\n]*' doesn't work well in old-vim, but "[^\r\n]*" works well
let s:skip_pattern = '\C^\%(\_s\+\|' . "#[^\r\n]*" . '\)'
let s:bare_key_pattern = '\%([A-Za-z0-9_-]\+\)'

function! s:_skip(input) abort
  while s:_match(a:input, '\%(\_s\|#\)')
    let a:input.p = matchend(a:input.text, s:skip_pattern, a:input.p)
  endwhile
endfunction

" XXX: old engine is faster than NFA engine (in this context).
if exists('+regexpengine')
  let s:regex_prefix = '\%#=1\C^'
else
  let s:regex_prefix = '\C^'
endif

function! s:_consume(input, pattern) abort
  call s:_skip(a:input)
  let end = matchend(a:input.text, s:regex_prefix . a:pattern, a:input.p)

  if end == -1
    call s:_error(a:input)
  elseif end == a:input.p
    return ''
  endif

  let matched = strpart(a:input.text, a:input.p, end - a:input.p)
  let a:input.p = end
  return matched
endfunction

function! s:_match(input, pattern) abort
  return match(a:input.text, s:regex_prefix . a:pattern, a:input.p) != -1
endfunction

function! s:_eof(input) abort
  return a:input.p >= a:input.length
endfunction

function! s:_error(input) abort
  let buf = []
  let offset = 0
  while (a:input.p + offset) < a:input.length && a:input.text[a:input.p + offset] !~# "[\r\n]"
    let buf += [a:input.text[a:input.p + offset]]
    let offset += 1
  endwhile

  throw printf("vital: Text.TOML: Illegal toml format at `%s'.", join(buf, ''))
endfunction

function! s:_parse(input) abort
  let data = {}

  call s:_skip(a:input)
  while !s:_eof(a:input)
    if s:_match(a:input, '[^ [:tab:]#.[\]]')
      let keys = s:_keys(a:input, '=')
      call s:_equals(a:input)
      let value = s:_value(a:input)
      call s:_put_dict(data, keys, value)
    elseif s:_match(a:input, '\[\[')
      let [keys, value] = s:_array_of_tables(a:input)
      call s:_put_array(data, keys, value)
    elseif s:_match(a:input, '\[')
      let [keys, value] = s:_table(a:input)
      call s:_put_dict(data, keys, value)
    else
      call s:_error(a:input)
    endif
    call s:_skip(a:input)
  endwhile

  return data
endfunction

function! s:_keys(input, end) abort
  let keys = []
  while !s:_eof(a:input) && !s:_match(a:input, a:end)
    call s:_skip(a:input)
    if s:_match(a:input, '"')
      let key = s:_basic_string(a:input)
    elseif s:_match(a:input, "'")
      let key = s:_literal(a:input)
    else
      let key = s:_consume(a:input, s:bare_key_pattern)
    endif
    let keys += [key]
    call s:_consume(a:input, '\.\?')
  endwhile
  if empty(keys)
    return s:_error(a:input)
  endif
  return keys
endfunction

function! s:_equals(input) abort
  return s:_consume(a:input, '=')
endfunction

function! s:_value(input) abort
  call s:_skip(a:input)

  if s:_match(a:input, '"\{3}')
    return s:_multiline_basic_string(a:input)
  elseif s:_match(a:input, '"\{1}')
    return s:_basic_string(a:input)
  elseif s:_match(a:input, "'\\{3}")
    return s:_multiline_literal(a:input)
  elseif s:_match(a:input, "'\\{1}")
    return s:_literal(a:input)
  elseif s:_match(a:input, '\[')
    return s:_array(a:input)
  elseif s:_match(a:input, '{')
    return s:_inline_table(a:input)
  elseif s:_match(a:input, '\%(true\|false\)')
    return s:_boolean(a:input)
  elseif s:_match(a:input, '\d\{4}-')
    return s:_datetime(a:input)
  elseif s:_match(a:input, '[+-]\?\d\+\%(_\d\+\)*\%(\.\d\+\%(_\d\+\)*\|\%(\.\d\+\%(_\d\+\)*\)\?[eE]\)')
    return s:_float(a:input)
  elseif s:_match(a:input, '[+-]\?\%(inf\|nan\)')
    return s:_special_float(a:input)
  else
    return s:_integer(a:input)
  endif
endfunction

"
" String
"
function! s:_basic_string(input) abort
  let s = s:_consume(a:input, '"\%(\\"\|[^"]\)*"')
  let s = s[1 : -2]
  return s:_unescape(s)
endfunction

function! s:_multiline_basic_string(input) abort
  let s = s:_consume(a:input, '"\{3}\%(\\.\|\_.\)\{-}"\{3}')
  let s = s[3 : -4]
  let s = substitute(s, "^\n", '', '')
  let s = substitute(s, '\\\s*' . "\n" . '\_s*', '', 'g')
  return s:_unescape(s)
endfunction

function! s:_literal(input) abort
  let s = s:_consume(a:input, "'[^']*'")
  return s[1 : -2]
endfunction

function! s:_multiline_literal(input) abort
  let s = s:_consume(a:input, "'\\{3}.\\{-}'\\{3}")
  let s = s[3 : -4]
  let s = substitute(s, "^\n", '', '')
  return s
endfunction

"
" Integer
"
function! s:_integer(input) abort
  let s = s:_consume(a:input, '[+-]\?\d\+\%(_\d\+\)*')
  let s = substitute(s, '_', '', 'g')
  return str2nr(s)
endfunction

"
" Float
"
function! s:_float(input) abort
  let s = s:_consume(a:input, '[+-]\?[0-9._]\+\%([eE][+-]\?\d\+\%(_\d\+\)*\)\?')
  let s = substitute(s, '_', '', 'g')
  return str2float(s)
endfunction

function! s:_special_float(input) abort
  let s = s:_consume(a:input, '[+-]\?\%(inf\|nan\)')
  return str2float(s)
endfunction

"
" Boolean
"
function! s:_boolean(input) abort
  let s = s:_consume(a:input, '\%(true\|false\)')
  return (s ==# 'true') ? 1 : 0
endfunction

"
" Datetime
"
function! s:_datetime(input) abort
  let s = s:_consume(a:input, '\d\{4}-\d\{2}-\d\{2}T\d\{2}:\d\{2}:\d\{2}\%(Z\|-\?\d\{2}:\d\{2}\|\.\d\+-\d\{2}:\d\{2}\)')
  return s
endfunction

"
" Array
"
function! s:_array(input) abort
  let ary = []
  let _ = s:_consume(a:input, '\[')
  call s:_skip(a:input)
  while !s:_eof(a:input) && !s:_match(a:input, '\]')
    let ary += [s:_value(a:input)]
    call s:_consume(a:input, ',\?')
    call s:_skip(a:input)
  endwhile
  let _ = s:_consume(a:input, '\]')
  return ary
endfunction

"
" Table
"
function! s:_table(input) abort
  let tbl = {}
  call s:_consume(a:input, '\[')
  let name = s:_keys(a:input, '\]')
  call s:_consume(a:input, '\]')
  call s:_skip(a:input)
  " while !s:_eof(a:input) && !s:_match(a:input, '\[\{1,2}[a-zA-Z0-9.]\+\]\{1,2}')
  while !s:_eof(a:input) && !s:_match(a:input, '\[')
    let keys = s:_keys(a:input, '=')
    call s:_equals(a:input)
    let value = s:_value(a:input)
    call s:_put_dict(tbl, keys, value)
    call s:_skip(a:input)
  endwhile
  return [name, tbl]
endfunction

"
" Inline Table
"
function! s:_inline_table(input) abort
  let tbl = {}
  call s:_consume(a:input, '{')
  while !s:_eof(a:input) && !s:_match(a:input, '}')
    let keys = s:_keys(a:input, '=')
    call s:_equals(a:input)
    let value = s:_value(a:input)
    call s:_put_dict(tbl, keys, value)
    call s:_consume(a:input, ',\?')
    call s:_skip(a:input)
  endwhile
  call s:_consume(a:input, '}')
  return tbl
endfunction

"
" Array of Tables
"
function! s:_array_of_tables(input) abort
  let tbl = {}
  call s:_consume(a:input, '\[\[')
  let name = s:_keys(a:input, '\]\]')
  call s:_consume(a:input, '\]\]')
  call s:_skip(a:input)
  " while !s:_eof(a:input) && !s:_match(a:input, '\[\{1,2}[a-zA-Z0-9.]\+\]\{1,2}')
  while !s:_eof(a:input) && !s:_match(a:input, '\[')
    let keys = s:_keys(a:input, '=')
    call s:_equals(a:input)
    let value = s:_value(a:input)
    call s:_put_dict(tbl, keys, value)
    call s:_skip(a:input)
  endwhile
  return [name, [tbl]]
endfunction

function! s:_unescape(text) abort
  let text = a:text
  let text = substitute(text, '\\"', '"', 'g')
  let text = substitute(text, '\\b', "\b", 'g')
  let text = substitute(text, '\\t', "\t", 'g')
  let text = substitute(text, '\\n', "\n", 'g')
  let text = substitute(text, '\\f', "\f", 'g')
  let text = substitute(text, '\\r', "\r", 'g')
  let text = substitute(text, '\\\\', '\', 'g')
  let text = substitute(text, '\C\\u\(\x\{4}\)', '\=s:_nr2char("0x" . submatch(1))', 'g')
  let text = substitute(text, '\C\\U\(\x\{8}\)', '\=s:_nr2char("0x" . submatch(1))', 'g')
  return text
endfunction

function! s:_nr2char(nr) abort
  return iconv(nr2char(a:nr), &encoding, 'utf8')
endfunction

function! s:_put_dict(dict, keys, value) abort
  let ref = a:dict
  for key in a:keys[: -2]
    if has_key(ref, key) && type(ref[key]) == v:t_dict
      let ref = ref[key]
    elseif has_key(ref, key) && type(ref[key]) == v:t_list
      let ref = ref[key][-1]
    else
      let ref[key] = {}
      let ref = ref[key]
    endif
  endfor

  let ref[a:keys[-1]] = a:value
endfunction

function! s:_put_array(dict, keys, value) abort
  let ref = a:dict
  for key in a:keys[: -2]
    let ref[key] = get(ref, key, {})

    if type(ref[key]) == v:t_list
      let ref = ref[key][-1]
    else
      let ref = ref[key]
    endif
  endfor

  let ref[a:keys[-1]] = get(ref, a:keys[-1], []) + a:value
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim:set et ts=2 sts=2 sw=2 tw=0:
