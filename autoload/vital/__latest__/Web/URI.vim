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

" Public Functions {{{

let s:NONE = []

function! s:_uri_new_sandbox(uri, ignore_rest, pattern_set, retall, NothrowValue) abort "{{{
  try
    let results = call('s:_uri_new', [a:uri, a:ignore_rest, a:pattern_set])
    return a:retall ? results : results[0]
  catch
    if a:NothrowValue isnot s:NONE && s:_is_own_exception(v:exception)
      return a:NothrowValue
    else
      let ex = substitute(v:exception, '^Vim([^()]\+):', '', '')
      throw ex . ' @ ' . v:throwpoint
    endif
  endtry
endfunction "}}}

function! s:_is_own_exception(str) abort "{{{
  return a:str =~# '^uri parse error:'
endfunction "}}}

function! s:new(uri, ...) abort "{{{
  let NothrowValue = get(a:000, 0, s:NONE)
  let pattern_set = get(a:000, 1, s:DefaultPatternSet)
  return s:_uri_new_sandbox(
  \   a:uri, 0, pattern_set, 0, NothrowValue)
endfunction "}}}

function! s:new_from_uri_like_string(str, ...) abort "{{{
  let NothrowValue = get(a:000, 0, s:NONE)
  let pattern_set  = get(a:000, 1, s:DefaultPatternSet)
  " Prepend http if no scheme.
  if a:str !~# '^'.pattern_set.get('scheme')
    let str = 'http://' . a:str
  else
    let str = a:str
  endif

  return s:_uri_new_sandbox(
  \   str, 0, pattern_set, 0, NothrowValue)
endfunction "}}}

function! s:new_from_seq_string(uri, ...) abort "{{{
  let NothrowValue = get(a:000, 0, s:NONE)
  let pattern_set  = get(a:000, 1, s:DefaultPatternSet)
  return s:_uri_new_sandbox(
  \   a:uri, 1, pattern_set, 1, NothrowValue)
endfunction "}}}

function! s:is_uri(str) abort "{{{
  let ERROR = []
  return s:new(a:str, ERROR) isnot ERROR
endfunction "}}}

function! s:like_uri(str) abort "{{{
  let ERROR = []
  return s:new_from_uri_like_string(a:str, ERROR) isnot ERROR
endfunction "}}}

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

" Parsing Functions {{{

" @return instance of s:URI .
"
" TODO: Support punycode
"
" Quoted the outline of RFC3986 here.
" RFC3986: http://tools.ietf.org/html/rfc3986
"
" URI = scheme ":" hier-part [ "?" query ] [ "#" fragment ]
" hier-part = "//" authority path-abempty
"           / path-absolute
"           / path-noscheme
"           / path-rootless
"           / path-empty
" authority = [ userinfo "@" ] host [ ":" port ]
function! s:_parse_uri(str, ignore_rest, pattern_set) abort "{{{
  let rest = a:str

  " Ignore leading/trailing whitespaces.
  let rest = substitute(rest, '^\s\+', '', '')
  let rest = substitute(rest, '\s\+$', '', '')

  " scheme
  let [scheme, rest] = s:_eat_scheme(rest, a:pattern_set)
  if scheme ==# ''
    throw 'uri parse error: could not parse scheme.'
  endif

  let rest = s:_eat_em(rest, '^://')[1]

  " userinfo
  try
    let oldrest = rest
    let [userinfo, rest] = s:_eat_userinfo(rest, a:pattern_set)
    let rest = s:_eat_em(rest, '^@')[1]
  catch
    let rest = oldrest
    let userinfo = ''
  endtry

  " host
  let [host, rest] = s:_eat_host(rest, a:pattern_set)
  if host ==# ''
    throw 'uri parse error: could not parse host.'
  endif

  " port
  if rest[0] ==# ':'
    let [port, rest] = s:_eat_port(rest[1:], a:pattern_set)
  else
    let port = ''
  endif

  " path (string after authority in hier-part)
  let [path, rest] = s:_eat_path(rest, a:pattern_set)

  " query
  if rest[0] ==# '?'
    let [query, rest] = s:_eat_query(rest[1:], a:pattern_set)
  else
    let query = ''
  endif

  " fragment
  if rest[0] ==# '#'
    let [fragment, rest] = s:_eat_fragment(rest[1:], a:pattern_set)
  else
    let fragment = ''
  endif

  if !a:ignore_rest && rest != ''
    throw 'uri parse error: unnecessary string at the end.'
  endif

  let obj = deepcopy(s:URI)
  let obj.__pattern_set = a:pattern_set
  " TODO: No need to use setter?
  " Just set property to directly.
  call obj.scheme(scheme)
  call obj.userinfo(userinfo)
  call obj.host(host)
  call obj.port(port)
  call obj.path(path)
  call obj.query(query)
  call obj.fragment(fragment)
  return [obj, rest]
endfunction "}}}

function! s:_eat_em(str, pat) abort "{{{
  let pat = a:pat.'\C'
  let match = matchstr(a:str, pat)
  if match ==# ''
    throw 'uri parse error: '
    \   . printf("can't parse '%s' with '%s'.", a:str, pat)
  endif
  let rest = strpart(a:str, strlen(match))
  return [match, rest]
endfunction "}}}

" NOTE: More s:_eat_*() functions are defined by s:_create_eat_functions().

" }}}

" s:URI {{{

function! s:_uri_new(str, ignore_rest, pattern_set) abort "{{{
  let [obj, rest] = s:_parse_uri(a:str, a:ignore_rest, a:pattern_set)
  if a:ignore_rest
    let original_url = a:str[: len(a:str)-len(rest)-1]
    return [obj, original_url, rest]
  else
    return [obj, a:str, '']
  endif
endfunction "}}}

function! s:_uri_scheme(...) dict abort "{{{
  if a:0 && self.is_scheme(a:1)
    let self.__scheme = a:1
  endif
  return self.__scheme
endfunction "}}}

function! s:_uri_userinfo(...) dict abort "{{{
  if a:0 && self.is_userinfo(a:1)
    let self.__userinfo = a:1
  endif
  return self.__userinfo
endfunction "}}}

function! s:_uri_host(...) dict abort "{{{
  if a:0 && self.is_host(a:1)
    let self.__host = a:1
  endif
  return self.__host
endfunction "}}}

function! s:_uri_port(...) dict abort "{{{
  if a:0 && self.is_port(a:1)
    let self.__port = a:1
  endif
  return self.__port
endfunction "}}}

function! s:_uri_path(...) dict abort "{{{
  if a:0
    " NOTE: self.__path must not have "/" as prefix.
    let path = substitute(a:1, '^/\+', '', '')
    if self.is_path(path)
      let self.__path = path
    endif
  endif
  return "/" . self.__path
endfunction "}}}

function! s:_uri_opaque(...) dict abort "{{{
  if a:0
    " TODO
    throw 'vital: Web.URI: uri.opaque(value) does not support yet.'
  endif
  return printf('//%s%s/%s',
  \           self.__host,
  \           (self.__port !=# '' ? ':' . self.__port : ''),
  \           self.__path)
endfunction "}}}

function! s:_uri_query(...) dict abort "{{{
  if a:0
    " NOTE: self.__query must not have "?" as prefix.
    let query = substitute(a:1, '^?', '', '')
    if self.is_query(query)
      let self.__query = query
    endif
  endif
  return self.__query
endfunction "}}}

function! s:_uri_fragment(...) dict abort "{{{
  if a:0
    " NOTE: self.__fragment must not have "#" as prefix.
    let fragment = substitute(a:1, '^#', '', '')
    if self.is_fragment(fragment)
      let self.__fragment = fragment
    endif
  endif
  return self.__fragment
endfunction "}}}

function! s:_uri_to_iri() dict abort "{{{
  " Same as uri.to_string(), but do unescape for self.__path.
  return printf(
  \   '%s://%s%s%s/%s%s%s',
  \   self.__scheme,
  \   (self.__userinfo != '' ? self.__userinfo . '@' : ''),
  \   self.__host,
  \   (self.__port !=# '' ? ':' . self.__port : ''),
  \   s:HTTP.decodeURI(self.__path),
  \   (self.__query != '' ? '?' . self.__query : ''),
  \   (self.__fragment != '' ? '#' . self.__fragment : ''),
  \)
endfunction "}}}

function! s:_uri_to_string() dict abort "{{{
  return printf(
  \   '%s://%s%s%s/%s%s%s',
  \   self.__scheme,
  \   (self.__userinfo != '' ? self.__userinfo . '@' : ''),
  \   self.__host,
  \   (self.__port !=# '' ? ':' . self.__port : ''),
  \   self.__path,
  \   (self.__query != '' ? '?' . self.__query : ''),
  \   (self.__fragment != '' ? '#' . self.__fragment : ''),
  \)
endfunction "}}}


let s:FUNCTION_DESCS = [
\ 'scheme', 'userinfo', 'host',
\ 'port', 'path', 'query', 'fragment'
\]

" Create s:_eat_*() functions.
function! s:_create_eat_functions() abort
  for where in s:FUNCTION_DESCS
    execute join([
    \ 'function! s:_eat_'.where.'(str, pattern_set) abort',
    \   'return s:_eat_em(a:str, "^" . a:pattern_set.get('.string(where).'))',
    \ 'endfunction',
    \], "\n")
  endfor
endfunction
call s:_create_eat_functions()

" Create s:_uri_is_*() functions.
function! s:_has_error(func, args) abort
  try
    call call(a:func, a:args)
    return 0
  catch
    return 1
  endtry
endfunction
function! s:_create_check_functions() abort
  for where in s:FUNCTION_DESCS
    execute join([
    \ 'function! s:_uri_is_'.where.'(str) dict abort',
    \   'return !s:_has_error("s:_eat_'.where.'", [a:str, self.__pattern_set])',
    \ 'endfunction',
    \], "\n")
  endfor
endfunction
call s:_create_check_functions()


function! s:_local_func(name) abort "{{{
  let sid = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__local_func$')
  return function('<SNR>' . sid . '_' . a:name)
endfunction "}}}

let s:URI = {
\ '__scheme': '',
\ '__userinfo': '',
\ '__host': '',
\ '__port': '',
\ '__path': '',
\ '__query': '',
\ '__fragment': '',
\
\ '__pattern_set': {},
\
\ 'scheme': s:_local_func('_uri_scheme'),
\ 'userinfo': s:_local_func('_uri_userinfo'),
\ 'host': s:_local_func('_uri_host'),
\ 'port': s:_local_func('_uri_port'),
\ 'path': s:_local_func('_uri_path'),
\ 'opaque': s:_local_func('_uri_opaque'),
\ 'query': s:_local_func('_uri_query'),
\ 'fragment': s:_local_func('_uri_fragment'),
\
\ 'to_iri': s:_local_func('_uri_to_iri'),
\ 'to_string': s:_local_func('_uri_to_string'),
\
\ 'is_scheme': s:_local_func('_uri_is_scheme'),
\ 'is_userinfo': s:_local_func('_uri_is_userinfo'),
\ 'is_host': s:_local_func('_uri_is_host'),
\ 'is_port': s:_local_func('_uri_is_port'),
\ 'is_path': s:_local_func('_uri_is_path'),
\ 'is_query': s:_local_func('_uri_is_query'),
\ 'is_fragment': s:_local_func('_uri_is_fragment'),
\}
" }}}

" s:PatternSet: Patterns for URI syntax {{{
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

let s:DefaultPatternSet = {'_cache': {}}

function! s:new_default_pattern_set() abort
  return deepcopy(s:DefaultPatternSet)
endfunction

" Memoize
function! s:DefaultPatternSet.get(component, ...) abort
  if has_key(self._cache, a:component)
    return self._cache[a:component]
  endif
  let ret = call(self[a:component], a:000, self)
  let self._cache[a:component] = ret
  return ret
endfunction

function! s:DefaultPatternSet.hexdig() abort
  return '[0-9A-Fa-f]'
endfunction
function! s:DefaultPatternSet.unreserved() abort
  return '[[:alpha:]0-9._~-]'
endfunction
function! s:DefaultPatternSet.pct_encoded() abort
  return '%' . self.hexdig() . self.hexdig()
endfunction
function! s:DefaultPatternSet.sub_delims() abort
  return '[!$&''()*+,;=]'
endfunction
function! s:DefaultPatternSet.dec_octet() abort
  return '\%([0-9]\|[1-9][0-9]\|1[0-9][0-9]\|2[0-4][0-9]\|25[0-5]\)'
endfunction
function! s:DefaultPatternSet.ipv4address() abort
  return self.dec_octet() . '\.' . self.dec_octet() . '\.' . self.dec_octet() . '\.' . self.dec_octet()
endfunction
function! s:DefaultPatternSet.ip_literal() abort
  " TODO
  " IP-literal    = "[" ( IPv6address / IPvFuture  ) "]"
  " IPvFuture     = "v" 1*HEXDIG "." 1*( unreserved / sub-delims / ":" )
  " IPv6address   =                            6( h16 ":" ) ls32
  "               /                       "::" 5( h16 ":" ) ls32
  "               / [               h16 ] "::" 4( h16 ":" ) ls32
  "               / [ *1( h16 ":" ) h16 ] "::" 3( h16 ":" ) ls32
  "               / [ *2( h16 ":" ) h16 ] "::" 2( h16 ":" ) ls32
  "               / [ *3( h16 ":" ) h16 ] "::"    h16 ":"   ls32
  "               / [ *4( h16 ":" ) h16 ] "::"              ls32
  "               / [ *5( h16 ":" ) h16 ] "::"              h16
  "               / [ *6( h16 ":" ) h16 ] "::"
endfunction
function! s:DefaultPatternSet.reg_name() abort
  return '\%(' . join([self.unreserved(), self.pct_encoded(), self.sub_delims()], '\|') . '\)*'
endfunction
function! s:DefaultPatternSet.pchar() abort
  return '\%(' . join([self.unreserved(), self.pct_encoded(), self.sub_delims(), ':', '@'], '\|') . '\)'
endfunction
function! s:DefaultPatternSet.segment() abort
  return self.pchar() . '*'
endfunction
function! s:DefaultPatternSet.segment_nz() abort
  return self.pchar()
endfunction
function! s:DefaultPatternSet.segment_nz_nc() abort
  return '\%(' . join([self.unreserved(), self.pct_encoded(), self.sub_delims(), '@'], '\|') . '\)'
endfunction
function! s:DefaultPatternSet.path_abempty() abort
  return '\%(/' . self.segment() . '\)*'
endfunction
function! s:DefaultPatternSet.path_absolute() abort
  return '/\%(' . self.segment_nz() . '\%(/' . self.segment() . '\)*\)\?'
endfunction
function! s:DefaultPatternSet.path_noscheme() abort
  return self.segment_nz_nc() . '\%(/' . self.segment() . '\)'
endfunction
function! s:DefaultPatternSet.path_rootless() abort
  return self.segment_nz() . '\%(/' . self.segment() . '\)*'
endfunction

function! s:DefaultPatternSet.scheme() abort
  return '[[:alpha:]][[:alpha:]0-9+.-]*'
endfunction
function! s:DefaultPatternSet.userinfo() abort
  return '\%(' . join([self.unreserved(), self.pct_encoded(), self.sub_delims(), ':'], '\|') . '\)*'
endfunction
function! s:DefaultPatternSet.host() abort
  return join([self.ipv4address(), self.reg_name()], '\|')
  " TODO
  " return join([self.ip_literal(), self.ipv4address(), self.reg_name()], '\|')
endfunction
function! s:DefaultPatternSet.port() abort
  return '[0-9]\+'
endfunction
function! s:DefaultPatternSet.path() abort
  return join([self.path_abempty(), self.path_absolute(), self.path_noscheme(), self.path_rootless(), ''], '\|')
endfunction
function! s:DefaultPatternSet.query() abort
  return '\%(' . join([self.pchar(), '/', '?'], '\|') . '\)*'
endfunction
function! s:DefaultPatternSet.fragment() abort
  return self.query()
endfunction

" }}}

" vim:set et ts=2 sts=2 sw=2 tw=0:fen:
