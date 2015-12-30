let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:HTTP = s:V.import('Web.HTTP')
endfunction

function! s:_vital_depends() abort
  return ['Web.HTTP']
endfunction

function! s:new(uri, ...) abort
  let NothrowValue = get(a:000, 0, s:NONE)
  let pattern_set = get(a:000, 1, s:DefaultPatternSet)
  return s:_uri_new_sandbox(
  \   a:uri, 0, pattern_set, 0, NothrowValue)
endfunction

function! s:new_from_uri_like_string(str, ...) abort
  let NothrowValue = get(a:000, 0, s:NONE)
  let pattern_set  = get(a:000, 1, s:DefaultPatternSet)
  " Prepend http if no scheme.
  if a:str !~# '^' . pattern_set.get('scheme') . '://'
    let str = 'http://' . a:str
  else
    let str = a:str
  endif

  return s:_uri_new_sandbox(
  \   str, 0, pattern_set, 0, NothrowValue)
endfunction

function! s:new_from_seq_string(uri, ...) abort
  let NothrowValue = get(a:000, 0, s:NONE)
  let pattern_set  = get(a:000, 1, s:DefaultPatternSet)
  return s:_uri_new_sandbox(
  \   a:uri, 1, pattern_set, 1, NothrowValue)
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


let s:NONE = []

function! s:_uri_new_sandbox(uri, ignore_rest, pattern_set, retall, NothrowValue) abort
  try
    let results = call('s:_uri_new', [a:uri, a:ignore_rest, a:pattern_set])
    return a:retall ? results : results[0]
  catch
    if a:NothrowValue isnot s:NONE && s:_is_own_exception(v:exception)
      return a:NothrowValue
    else
      let ex = substitute(v:exception, '^Vim([^()]\+):', '', '')
      throw 'vital: Web.URI: ' . ex . ' @ ' . v:throwpoint
      \   . ' (original URI: ' . a:uri . ')'
    endif
  endtry
endfunction

function! s:_is_own_exception(str) abort
  return a:str =~# '^uri parse error\%(([^)]\+)\)\?:'
endfunction


" ================ Parsing Functions ================

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
function! s:_parse_uri(str, ignore_rest, pattern_set) abort
  let rest = a:str

  " Ignore leading/trailing whitespaces.
  let rest = substitute(rest, '^\s\+', '', '')
  let rest = substitute(rest, '\s\+$', '', '')

  " scheme
  let [scheme, rest] = s:_eat_scheme(rest, a:pattern_set)

  " hier-part
  let [hier_part, rest] = s:_eat_hier_part(rest, a:pattern_set)

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

  if !a:ignore_rest && rest !=# ''
    throw 'uri parse error: unnecessary string at the end.'
  endif

  let obj = deepcopy(s:URI)
  let obj.__pattern_set = a:pattern_set
  let obj.__scheme = scheme
  let obj.__userinfo = hier_part.userinfo
  let obj.__host = hier_part.host
  let obj.__port = hier_part.port
  " NOTE: obj.__path must not have "/" as prefix.
  let obj.__path = substitute(hier_part.path, '^/\+', '', '')
  " NOTE: obj.__query must not have "?" as prefix.
  let obj.__query = substitute(query, '^?', '', '')
  " NOTE: obj.__fragment must not have "#" as prefix.
  let obj.__fragment = substitute(fragment, '^#', '', '')
  return [obj, rest]
endfunction

function! s:_eat_em(str, pat, ...) abort
  let pat = a:pat.'\C'
  let m = matchlist(a:str, pat)
  if empty(m)
    let prefix = printf('uri parse error%s: ', (a:0 ? '('.a:1.')' : ''))
    let msg = printf("can't parse '%s' with '%s'.", a:str, pat)
    throw prefix . msg
  endif
  let rest = strpart(a:str, strlen(m[0]))
  return [m[0], rest]
endfunction

function! s:_eat_hier_part(rest, pattern_set) abort
  let rest = a:rest
  if rest =~# '^://'
    " authority
    let rest = rest[3:]
    " authority(userinfo)
    try
      let oldrest = rest
      let [userinfo, rest] = s:_eat_userinfo(rest, a:pattern_set)
      let rest = s:_eat_em(rest, '^@')[1]
    catch
      let rest = oldrest
      let userinfo = ''
    endtry
    " authority(host)
    let [host, rest] = s:_eat_host(rest, a:pattern_set)
    " authority(port)
    if rest[0] ==# ':'
      let [port, rest] = s:_eat_port(rest[1:], a:pattern_set)
    else
      let port = ''
    endif
    " path
    let [path, rest] = s:_eat_path_abempty(rest, a:pattern_set)
  elseif rest =~# ':'
    let rest = rest[1:]
    let userinfo = ''
    let host = ''
    let port = ''
    " path
    if rest =~# '^/[^/]'    " begins with '/' but not '//'
      let [path, rest] = s:_eat_path_absolute(rest, a:pattern_set)
    elseif rest =~# '^[^:]'    " begins with a non-colon segment
      let [path, rest] = s:_eat_path_noscheme(rest, a:pattern_set)
    elseif rest =~# a:pattern_set.segment_nz()    " begins with a segment
      let [path, rest] = s:_eat_path_rootless(rest, a:pattern_set)
    elseif rest ==# '' || rest =~# '^[?#]'    " zero characters
      let path = ''
    else
      throw printf("uri parse error(hier-part): can't parse '%s'.", rest)
    endif
  else
    throw printf("uri parse error(hier-part): can't parse '%s'.", rest)
  endif
  return [{
  \ 'userinfo': userinfo,
  \ 'host': host,
  \ 'port': port,
  \ 'path': path,
  \}, rest]
endfunction

" NOTE: More s:_eat_*() functions are defined by s:_create_eat_functions().
" =============== Parsing Functions ===============


" ===================== s:URI =====================

function! s:_uri_new(str, ignore_rest, pattern_set) abort
  let [obj, rest] = s:_parse_uri(a:str, a:ignore_rest, a:pattern_set)
  if a:ignore_rest
    let original_url = a:str[: len(a:str)-len(rest)-1]
    return [obj, original_url, rest]
  else
    return [obj, a:str, '']
  endif
endfunction

function! s:_uri_scheme(...) dict abort
  if a:0
    if self.is_scheme(a:1)
      let self.__scheme = a:1
    else
      throw 'vital: Web.URI: scheme(): '
      \   . 'invalid argument (' . string(a:1) . ')'
    endif
  endif
  return self.__scheme
endfunction

function! s:_uri_userinfo(...) dict abort
  if a:0
    if self.is_userinfo(a:1)
      let self.__userinfo = a:1
    else
      throw 'vital: Web.URI: userinfo(): '
      \   . 'invalid argument (' . string(a:1) . ')'
    endif
  endif
  return self.__userinfo
endfunction

function! s:_uri_host(...) dict abort
  if a:0
    if self.is_host(a:1)
      let self.__host = a:1
    else
      throw 'vital: Web.URI: host(): '
      \   . 'invalid argument (' . string(a:1) . ')'
    endif
  endif
  return self.__host
endfunction

function! s:_uri_port(...) dict abort
  if a:0
    if self.is_port(a:1)
      let self.__port = a:1
    else
      throw 'vital: Web.URI: port(): '
      \   . 'invalid argument (' . string(a:1) . ')'
    endif
  endif
  return self.__port
endfunction

function! s:_uri_path(...) dict abort
  if a:0
    " NOTE: self.__path must not have "/" as prefix.
    let path = substitute(a:1, '^/\+', '', '')
    if self.is_path(path)
      let self.__path = path
    else
      throw 'vital: Web.URI: path(): '
      \   . 'invalid argument (' . string(a:1) . ')'
    endif
  endif
  return "/" . self.__path
endfunction

function! s:_uri_authority(...) dict abort
  if a:0
    " TODO
    throw 'vital: Web.URI: uri.authority(value) does not support yet.'
  endif
  return
  \   (self.__userinfo !=# '' ? self.__userinfo . '@' : '')
  \   . self.__host
  \   . (self.__port !=# '' ? ':' . self.__port : '')
endfunction

function! s:_uri_opaque(...) dict abort
  if a:0
    " TODO
    throw 'vital: Web.URI: uri.opaque(value) does not support yet.'
  endif
  return printf('//%s/%s',
  \           self.authority(),
  \           self.__path)
endfunction

function! s:_uri_query(...) dict abort
  if a:0
    " NOTE: self.__query must not have "?" as prefix.
    let query = substitute(a:1, '^?', '', '')
    if self.is_query(query)
      let self.__query = query
    else
      throw 'vital: Web.URI: query(): '
      \   . 'invalid argument (' . string(a:1) . ')'
    endif
  endif
  return self.__query
endfunction

function! s:_uri_fragment(...) dict abort
  if a:0
    " NOTE: self.__fragment must not have "#" as prefix.
    let fragment = substitute(a:1, '^#', '', '')
    if self.is_fragment(fragment)
      let self.__fragment = fragment
    else
      throw 'vital: Web.URI: fragment(): '
      \   . 'invalid argument (' . string(a:1) . ')'
    endif
  endif
  return self.__fragment
endfunction

function! s:_uri_to_iri() dict abort
  " Same as uri.to_string(), but do unescape for self.__path.
  return printf(
  \   '%s://%s/%s%s%s',
  \   self.__scheme,
  \   self.authority(),
  \   s:HTTP.decodeURI(self.__path),
  \   (self.__query !=# '' ? '?' . self.__query : ''),
  \   (self.__fragment !=# '' ? '#' . self.__fragment : ''),
  \)
endfunction

function! s:_uri_to_string() dict abort
  return printf(
  \   '%s://%s/%s%s%s',
  \   self.__scheme,
  \   self.authority(),
  \   self.__path,
  \   (self.__query !=# '' ? '?' . self.__query : ''),
  \   (self.__fragment !=# '' ? '#' . self.__fragment : ''),
  \)
endfunction


let s:FUNCTION_DESCS = [
\ 'scheme', 'userinfo', 'host',
\ 'port', 'path', 'path_abempty',
\ 'path_absolute', 'path_noscheme',
\ 'path_rootless',
\ 'query', 'fragment'
\]

" Create s:_eat_*() functions.
function! s:_create_eat_functions() abort
  for where in s:FUNCTION_DESCS
    execute join([
    \ 'function! s:_eat_'.where.'(str, pattern_set) abort',
    \   'return s:_eat_em(a:str, "^" . a:pattern_set.get('.string(where).'), '.string(where).')',
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


function! s:_local_func(name) abort
  let sid = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__local_func$')
  return function('<SNR>' . sid . '_' . a:name)
endfunction

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
\ 'authority': s:_local_func('_uri_authority'),
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

" ===================== s:URI =====================


" ================= s:PatternSet ==================
" s:PatternSet: Patterns for URI syntax
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
  let pattern_set = deepcopy(s:DefaultPatternSet)
  let pattern_set._cache = {}
  return pattern_set
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

" unreserved    = ALPHA / DIGIT / "." / "_" / "~" / "-"
function! s:DefaultPatternSet.unreserved() abort
  return '[[:alpha:]0-9._~-]'
endfunction
" pct-encoded   = "%" HEXDIG HEXDIG
function! s:DefaultPatternSet.pct_encoded() abort
  return '%\x\x'
endfunction
" sub-delims    = "!" / "$" / "&" / "'" / "(" / ")"
"               / "*" / "+" / "," / ";" / "="
function! s:DefaultPatternSet.sub_delims() abort
  return '[!$&''()*+,;=]'
endfunction
" dec-octet   = DIGIT                 ; 0-9
"             / %x31-39 DIGIT         ; 10-99
"             / "1" 2DIGIT            ; 100-199
"             / "2" %x30-34 DIGIT     ; 200-249
"             / "25" %x30-35          ; 250-255
function! s:DefaultPatternSet.dec_octet() abort
  return '\%(1[0-9][0-9]\|2[0-4][0-9]\|25[0-5]\|[1-9][0-9]\|[0-9]\)'
endfunction
" IPv4address = dec-octet "." dec-octet "." dec-octet "." dec-octet
function! s:DefaultPatternSet.ipv4address() abort
  return self.dec_octet() . '\.' . self.dec_octet()
  \    . '\.' . self.dec_octet() . '\.' . self.dec_octet()
endfunction
" IPv6address =                            6( h16 ":" ) ls32
"             /                       "::" 5( h16 ":" ) ls32
"             / [               h16 ] "::" 4( h16 ":" ) ls32
"             / [ *1( h16 ":" ) h16 ] "::" 3( h16 ":" ) ls32
"             / [ *2( h16 ":" ) h16 ] "::" 2( h16 ":" ) ls32
"             / [ *3( h16 ":" ) h16 ] "::"    h16 ":"   ls32
"             / [ *4( h16 ":" ) h16 ] "::"              ls32
"             / [ *5( h16 ":" ) h16 ] "::"              h16
"             / [ *6( h16 ":" ) h16 ] "::"
"
" NOTE: Using repeat() in some parts because
" can't use /\{ at most 10 in whole regexp.
" https://github.com/vim/vim/blob/cde885473099296c4837de261833f48b24caf87c/src/regexp.c#L1884
function! s:DefaultPatternSet.ipv6address() abort
  return '\%(' . join([
  \ (repeat('\%(' . self.h16() . ':\)', 6) . self.ls32()),
  \ ('::' . repeat('\%(' . self.h16() . ':\)', 5) . self.ls32()),
  \ ('\%(' . self.h16() . '\)\?::'
  \   . repeat('\%(' . self.h16() . ':\)', 4) . self.ls32()),
  \ ('\%(\%(' . self.h16() . ':\)\?'    . self.h16() . '\)\?::'
  \   . repeat('\%(' . self.h16() . ':\)', 3) . self.ls32()),
  \ ('\%(\%(' . self.h16() . ':\)\{,2}' . self.h16() . '\)\?::'
  \   . repeat('\%(' . self.h16() . ':\)', 2) . self.ls32()),
  \ ('\%(\%(' . self.h16() . ':\)\{,3}' . self.h16() . '\)\?::'
  \   . self.h16() . ':' . self.ls32()),
  \ ('\%(\%(' . self.h16() . ':\)\{,4}' . self.h16() . '\)\?::' . self.ls32()),
  \ ('\%(\%(' . self.h16() . ':\)\{,5}' . self.h16() . '\)\?::' . self.h16()),
  \ ('\%(\%(' . self.h16() . ':\)\{,6}' . self.h16() . '\)\?::')
  \], '\|') . '\)'
endfunction
" h16 = 1*4HEXDIG
"     ; 16 bits of address represented in hexadecimal
function! s:DefaultPatternSet.h16() abort
  return '\x\{1,4}'
endfunction
" ls32 = ( h16 ":" h16 ) / IPv4address
"      ; least-significant 32 bits of address
function! s:DefaultPatternSet.ls32() abort
  return '\%(' . self.h16() . ':' . self.h16()
  \    . '\|' . self.ipv4address() . '\)'
endfunction
" IPvFuture = "v" 1*HEXDIG "." 1*( unreserved / sub-delims / ":" )
function! s:DefaultPatternSet.ipv_future() abort
  return 'v\x\+\.'
  \    . '\%(' . join([self.unreserved(),
  \                    self.sub_delims(), ':'], '\|') . '\)\+'
endfunction
" IP-Literal = "[" ( IPv6address / IPvFuture  ) "]"
function! s:DefaultPatternSet.ip_literal() abort
  return '\[\%(' . self.ipv6address() . '\|' . self.ipv_future() . '\)\]'
endfunction
" reg-name = *( unreserved / pct-encoded / sub-delims )
function! s:DefaultPatternSet.reg_name() abort
  return '\%(' . join([self.unreserved(), self.pct_encoded(),
  \                    self.sub_delims()], '\|') . '\)*'
endfunction
" pchar = unreserved / pct-encoded / sub-delims / ":" / "@"
function! s:DefaultPatternSet.pchar() abort
  return '\%(' . join([self.unreserved(), self.pct_encoded(),
  \                    self.sub_delims(), ':', '@'], '\|') . '\)'
endfunction
" segment = *pchar
function! s:DefaultPatternSet.segment() abort
  return self.pchar() . '*'
endfunction
" segment-nz = 1*pchar
function! s:DefaultPatternSet.segment_nz() abort
  return self.pchar() . '\+'
endfunction
" segment-nz-nc = 1*( unreserved / pct-encoded / sub-delims / "@" )
"               ; non-zero-length segment without any colon ":"
function! s:DefaultPatternSet.segment_nz_nc() abort
  return '\%(' . join([self.unreserved(), self.pct_encoded(),
  \                    self.sub_delims(), '@'], '\|') . '\)\+'
endfunction
" path-abempty = *( "/" segment )
function! s:DefaultPatternSet.path_abempty() abort
  return '\%(/' . self.segment() . '\)*'
endfunction
" path-absolute = "/" [ segment-nz *( "/" segment ) ]
function! s:DefaultPatternSet.path_absolute() abort
  return '/\%(' . self.segment_nz() . '\%(/' . self.segment() . '\)*\)\?'
endfunction
" path-noscheme = segment-nz-nc *( "/" segment )
function! s:DefaultPatternSet.path_noscheme() abort
  return self.segment_nz_nc() . '\%(/' . self.segment() . '\)*'
endfunction
" path-rootless = segment-nz *( "/" segment )
function! s:DefaultPatternSet.path_rootless() abort
  return self.segment_nz() . '\%(/' . self.segment() . '\)*'
endfunction

" scheme = ALPHA *( ALPHA / DIGIT / "+" / "." / "-" )
function! s:DefaultPatternSet.scheme() abort
  return '[[:alpha:]][[:alpha:]0-9+.-]*'
endfunction
" userinfo = *( unreserved / pct-encoded / sub-delims / ":" )
function! s:DefaultPatternSet.userinfo() abort
  return '\%(' . join([self.unreserved(), self.pct_encoded(),
  \                    self.sub_delims(), ':'], '\|') . '\)*'
endfunction
" host = IP-literal / IPv4address / reg-name
function! s:DefaultPatternSet.host() abort
  return '\%(' . join([self.ip_literal(), self.ipv4address(),
  \                    self.reg_name()], '\|') . '\)'
endfunction
" port = *DIGIT
function! s:DefaultPatternSet.port() abort
  return '[0-9]\+'
endfunction
" path = path-abempty    ; begins with "/" or is empty
"      / path-absolute   ; begins with "/" but not "//"
"      / path-noscheme   ; begins with a non-colon segment
"      / path-rootless   ; begins with a segment
"      / path-empty      ; zero characters
function! s:DefaultPatternSet.path() abort
  return '\%(' . join([self.path_abempty(), self.path_absolute(),
  \                    self.path_noscheme(), self.path_rootless(),
  \                    ''], '\|') . '\)'
endfunction
" query = *( pchar / "/" / "?" )
function! s:DefaultPatternSet.query() abort
  return '\%(' . join([self.pchar(), '/', '?'], '\|') . '\)*'
endfunction
" fragment = *( pchar / "/" / "?" )
function! s:DefaultPatternSet.fragment() abort
  return '\%(' . join([self.pchar(), '/', '?'], '\|') . '\)*'
endfunction

" ================= s:PatternSet ==================

" vim:set et ts=2 sts=2 sw=2 tw=0:fen:
