let s:save_cpo = &cpo
set cpo&vim

" Imports {{{

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:HTTP = s:V.import('Web.HTTP')
endfunction

function! s:_vital_depends() abort
  return ['Web.HTTP']
endfunction

" }}}

" Autoload Functions {{{

let s:NONE = []

function! s:_uri_new_sandbox(args, retall, NothrowValue) abort
  try
    let results = call('s:_uri_new', a:args)
    return a:retall ? results : results[0]
  catch
    if a:NothrowValue isnot s:NONE && s:_is_own_exception(v:exception)
      return a:NothrowValue
    else
      throw substitute(v:exception, '^Vim([^()]\+):', '', '')
    endif
  endtry
endfunction

function! s:_is_own_exception(str) abort
  return a:str =~# '^uri parse error:'
endfunction

function! s:new(uri, ...) abort
  let NothrowValue = a:0 ? a:1 : s:NONE
  return s:_uri_new_sandbox(
  \   [a:uri], 0, NothrowValue)
endfunction

function! s:new_from_uri_like_string(str, ...) abort
  let str = a:str
  if str !~# s:RX_SCHEME    " no scheme.
    let str = 'http://' . str
  endif

  let NothrowValue = a:0 ? a:1 : s:NONE
  return s:_uri_new_sandbox(
  \   [str], 0, NothrowValue)
endfunction

function! s:new_from_seq_string(uri, ...) abort
  let NothrowValue = a:0 ? a:1 : s:NONE
  return s:_uri_new_sandbox(
  \   [a:uri, 1], 1, NothrowValue)
endfunction

function! s:is_uri(str) abort
  let ERROR = []
  return s:new(a:str, ERROR) isnot ERROR
endfunction

function! s:like_uri(str) abort
  let ERROR = []
  return s:new_from_uri_like_string(a:str, ERROR) isnot ERROR
endfunction

function! s:encode(str, ...) abort
  let encoding = a:0 ? a:1 : 'utf-8'
  if encoding ==# ''
    let str = a:str
  else
    let str = iconv(a:str, &encoding, encoding)
  endif

  let result = ''
  for i in range(len(str))
    if str[i] =~# '^[a-zA-Z0-9_.~-]$'
      let result .= str[i]
    else
      let result .= printf('%%%02X', char2nr(str[i]))
    endif
  endfor
  return result
endfunction

function! s:decode(str, ...) abort
  let result = substitute(a:str, '%\(\x\x\)',
  \   '\=printf("%c", str2nr(submatch(1), 16))', 'g')

  let encoding = a:0 ? a:1 : 'utf-8'
  if encoding ==# ''
    return result
  endif
  return iconv(result, encoding, &encoding)
endfunction

" }}}

" URI Object {{{

function! s:_uri_new(str, ...) abort
  let ignore_rest = (a:0 ? a:1 : 0)
  let [result, rest] = s:_parse_uri(a:str, ignore_rest)
  " TODO: Support punycode
  " let result.host = ...

  let obj = deepcopy(s:uri)
  for [where, value] in items(result)
    call s:_validate_{where}(value)         " Validate the value.
    call call(obj[where], [value], obj)    " Set the value.
  endfor

  let original_url = a:str[: len(a:str)-len(rest)-1]
  return [obj, original_url, rest]
endfunction

function! s:_uri_scheme(...) dict abort
  if a:0 && s:_is_scheme(a:1)
    let self.__scheme = a:1
  endif
  return self.__scheme
endfunction

function! s:_uri_host(...) dict abort
  if a:0 && s:_is_host(a:1)
    let self.__host = a:1
  endif
  return self.__host
endfunction

function! s:_uri_port(...) dict abort
  if a:0 && s:_is_port(a:1)
    let self.__port = a:1
  endif
  return self.__port
endfunction

function! s:_uri_path(...) dict abort
  if a:0
    " NOTE: self.__path must not have "/" as prefix.
    let path = substitute(a:1, '^/\+', '', '')
    if s:_is_path(path)
      let self.__path = path
    endif
  endif
  return "/" . self.__path
endfunction

function! s:_uri_opaque(...) dict abort
  if a:0
    " TODO
    throw 'vital: Web.URI: uri.opaque(value) does not support yet.'
  endif
  return printf('//%s%s/%s',
  \           self.__host,
  \           (self.__port !=# '' ? ':' . self.__port : ''),
  \           self.__path)
endfunction

function! s:_uri_fragment(...) dict abort
  if a:0
    " NOTE: self.__fragment must not have "#" as prefix.
    let fragment = substitute(a:1, '^#', '', '')
    if s:_is_fragment(fragment)
      let self.__fragment = fragment
    endif
  endif
  return self.__fragment
endfunction

function! s:_uri_query(...) dict abort
  if a:0
    " NOTE: self.__query must not have "?" as prefix.
    let query = substitute(a:1, '^?', '', '')
    if s:_is_query(query)
      let self.__query = query
    endif
  endif
  return self.__query
endfunction

function! s:_uri_to_iri() dict abort
  " Same as uri.to_string(), but do unescape for self.__path.
  return printf(
  \   '%s://%s%s/%s%s%s',
  \   self.__scheme,
  \   self.__host,
  \   (self.__port !=# '' ? ':' . self.__port : ''),
  \   s:HTTP.decodeURI(self.__path),
  \   (self.__query != '' ? '?' . self.__query : ''),
  \   (self.__fragment != '' ? '#' . self.__fragment : ''),
  \)
endfunction

function! s:_uri_to_string() dict abort
  return printf(
  \   '%s://%s%s/%s%s%s',
  \   self.__scheme,
  \   self.__host,
  \   (self.__port !=# '' ? ':' . self.__port : ''),
  \   self.__path,
  \   (self.__query != '' ? '?' . self.__query : ''),
  \   (self.__fragment != '' ? '#' . self.__fragment : ''),
  \)
endfunction



function! s:_local_func(name) abort
  let sid = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__local_func$')
  return function('<SNR>' . sid . '_' . a:name)
endfunction

let s:uri = {
\ '__scheme': '',
\ '__host': '',
\ '__port': '',
\ '__path': '',
\ '__query': '',
\ '__fragment': '',
\
\ 'scheme': s:_local_func('_uri_scheme'),
\ 'host': s:_local_func('_uri_host'),
\ 'port': s:_local_func('_uri_port'),
\ 'path': s:_local_func('_uri_path'),
\ 'opaque': s:_local_func('_uri_opaque'),
\ 'query': s:_local_func('_uri_query'),
\ 'fragment': s:_local_func('_uri_fragment'),
\ 'to_iri': s:_local_func('_uri_to_iri'),
\ 'to_string': s:_local_func('_uri_to_string'),
\}
" }}}

" Parsing Functions {{{

function! s:_parse_uri(str, ignore_rest) abort
  let rest = a:str

  " Ignore leading/trailing whitespaces.
  let rest = substitute(rest, '^\s\+', '', '')
  let rest = substitute(rest, '\s\+$', '', '')

  " URI = scheme ":" hier-part [ "?" query ] [ "#" fragment ]
  " hier-part = "//" authority path-abempty
  "           / path-absolute
  "           / path-rootless
  "           / path-empty
  " authority = [ userinfo "@" ] host [ ":" port ]

  " scheme
  let [scheme, rest] = s:_eat_scheme(rest)

  let rest = s:_eat_em(rest, '^://')[1]

  " TODO: userinfo

  " host
  let [host, rest] = s:_eat_host(rest)

  " port
  if rest[0] ==# ':'
    let [port, rest] = s:_eat_port(rest[1:])
  else
    let port = ''
  endif

  " path (string after authority in hier-part)
  let [path, rest] = s:_eat_path(rest)

  " query
  if rest[0] ==# '?'
    let [query, rest] = s:_eat_query(rest[1:])
  else
    let query = ''
  endif

  " fragment
  if rest[0] ==# '#'
    let [fragment, rest] = s:_eat_fragment(rest[1:])
  else
    let fragment = ''
  endif

  if !a:ignore_rest && rest != ''
    throw 'uri parse error: unnecessary string at the end.'
  endif

  return [{
  \ 'scheme': scheme,
  \ 'host': host,
  \ 'port': port,
  \ 'path': path,
  \ 'query': query,
  \ 'fragment': fragment,
  \}, rest]
endfunction
function! s:_eat_em(str, pat) abort
  let pat = a:pat.'\C'
  let m = matchlist(a:str, pat)
  if empty(m)
    throw 'uri parse error: '
    \   . printf("can't parse '%s' with '%s'.", a:str, pat)
  endif
  let [match, want] = m[0:1]
  let rest = strpart(a:str, strlen(match))
  return [want, rest]
endfunction


" Patterns for URI syntax {{{
"
" The main parts of URLs
"   http://tools.ietf.org/html/rfc1738#section-2.1
" BNF for specific URL schemes
"   http://tools.ietf.org/html/rfc1738#section-5
" Collected ABNF for URI
"   http://tools.ietf.org/html/rfc3986#appendix-A
" Parsing a URI Reference with a Regular Expression
" NOTE: Using this regexp pattern in urilib.vim
"   http://tools.ietf.org/html/rfc3986#appendix-B

let s:RX_SCHEME   = '^\([^:/?#[:space:]]\+\)'
let s:RX_HOST     = '^\([^/?#[:space:]]*\)'
let s:RX_PORT     = '^\(\d*\)'
let s:RX_PATH     = '^\([^?#[:space:]]*\)'
let s:RX_QUERY    = '^\([^#[:space:]]*\)'
let s:RX_FRAGMENT = '^\([^[:space:]]*\)'
" }}}

" FIXME: make error messages user-friendly.
let s:FUNCTION_DESCS = {
\ 'scheme': 'uri parse error: all characters'
\         . ' in scheme must be [a-z].',
\ 'host': 'uri parse error: all characters'
\       . ' in host must be [\x00-\xff].',
\ 'port': 'uri parse error: all characters'
\       . ' in port must be digit and the number'
\       . ' is greater than 0.',
\ 'path': 'uri parse error: all characters'
\       . ' in path must be [\x00-\xff].',
\ 'query': 'uri parse error: all characters'
\       . ' in query must be [\x00-\xff].',
\ 'fragment': 'uri parse error: all characters'
\           . ' in fragment must be [\x00-\xff].',
\}

" Create s:_eat_*() functions.
function! s:_create_eat_functions() abort
  for where in keys(s:FUNCTION_DESCS)
    execute join([
    \ 'function! s:_eat_'.where.'(str) abort',
    \   'return s:_eat_em(a:str, s:RX_'.toupper(where).')',
    \ 'endfunction',
    \], "\n")
  endfor
endfunction
call s:_create_eat_functions()

" Create s:_is_*() functions.
function! s:_has_error(func, args) abort
  try
    call call(a:func, a:args)
    return 0
  catch
    return 1
  endtry
endfunction
function! s:_create_check_functions() abort
  for where in keys(s:FUNCTION_DESCS)
    execute join([
    \ 'function! s:_is_'.where.'(str) abort',
    \   'return !s:_has_error("s:_eat_'.where.'", [a:str])',
    \ 'endfunction',
    \], "\n")
  endfor
endfunction
call s:_create_check_functions()

" Create s:_validate_*() functions.
function! s:_create_validate_functions() abort
  for [where, msg] in items(s:FUNCTION_DESCS)
    execute join([
    \ 'function! s:_validate_'.where.'(str) abort',
    \   'if !s:_is_'.where.'(a:str)',
    \     'throw '.string(msg),
    \   'endif',
    \ 'endfunction',
    \], "\n")
  endfor
endfunction
call s:_create_validate_functions()

" }}}

" vim:set et ts=2 sts=2 sw=2 tw=0:fen:
