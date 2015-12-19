let s:save_cpo = &cpoptions
set cpoptions&vim

" RFC: http://tools.ietf.org/html/rfc6265
" Japanese Translation: http://www.hcn.zaq.ne.jp/___/WEB/RFC6265-ja.html


function! s:_vital_loaded(V) abort
  let s:String = a:V.import('Data.String')
  let s:URI = a:V.import('Web.URI')
  let s:DateTime = a:V.import('DateTime')
endfunction

function! s:_vital_depends() abort
  return ['Data.String', 'DateTime', 'Web.URI']
endfunction


let s:ATTR_NAMES = {
\   'expires': 'Expires',
\   'max-age': 'Max-Age',
\   'domain': 'Domain',
\   'path': 'Path',
\   'secure': 'Secure',
\   'httponly': 'HttpOnly',
\ }
function! s:_normalized_attr_name(attr_name) abort
  return get(s:ATTR_NAMES, tolower(a:attr_name), '')
endfunction

function! s:new(cookie_string, request_uri) abort
  let req_uri = s:URI.new(a:request_uri)
  let cookie = deepcopy(s:Cookie)
  let cookie._creation_time = s:DateTime.now()
  let cookie._last_access_time = cookie._creation_time

  let entries = split(a:cookie_string, '\s*;\s*')
  let name_value = remove(entries, 0)
  let [cookie._name, cookie._value] = s:_parse_cookie_value(name_value)
  for entry in entries
    let attr = split(entry, '\s*=\s*')
    let attr_name = s:_normalized_attr_name(attr[0])
    if attr_name ==# ''
      continue
    endif
    let value = get(attr, 1, '')
    if attr_name ==# 'Expires'
      " TODO: Check DateTime format
    elseif attr_name ==# 'Max-Age'
      if value !~# '^-\?\d\+$'
        continue
      endif
      let value = str2nr(value)
    elseif attr_name ==# 'Secure' || attr_name ==# 'HttpOnly'
      let value = ''
    endif
    let cookie._attributes[attr_name] = value
  endfor

  if has_key(cookie._attributes, 'Domain')
    let cookie._domain =
    \   tolower(matchstr(cookie._attributes['Domain'], '^\.*\zs.*'))
    if !s:_is_match_domain(req_uri.host(), cookie._domain)
      let cookie._is_valid = 0
    endif
  else
    let cookie._domain = req_uri.host()
  endif

  if has_key(cookie._attributes, 'Path')
    let value = cookie._attributes['Path']
    if value[0] !=# '/'
      let cookie._path = s:_get_default_path(req_uri.path())
    else
      let cookie._path = value
    endif
  else
    let cookie._path = s:_get_default_path(req_uri.path())
  endif

  return cookie
endfunction

function! s:_parse_cookie_value(name_value) abort
  let [name, value] = matchlist(a:name_value, '^\([^=]*\)\%(=\(.*\)\)\?')[1 : 2]
  return [name, s:_parse_cookie_str(value)]
endfunction

function! s:_parse_cookie_str(str) abort
  let i = 0
  let end = len(a:str)
  let parsed_str = ''
  let quoted = 0
  while i < end
    if a:str[i : i + 2] =~# '%\x\x'
      let parsed_str .= printf('%c', str2nr(a:str[i + 1 : i + 2], 16))
      let i += 3
      continue
    endif
    if a:str[i] ==# '\'
      if !quoted
        let parsed_str .= '\'
        let i += 1
        continue
      endif
      let front = a:str[i + 1 : i + 3]
      if front =~# '^\d\+$'
        let parsed_str .= printf('%c', str2nr(front, 8))
        let i += 4
      else
        let parsed_str .= front[0]
        let i += 2
      endif
      continue
    endif
    if a:str[i] ==# '"'
      let quoted = !quoted
      let i += 1
      continue
    endif
    let plain = matchstr(a:str, '[^%\\"]*', i)
    let parsed_str .= plain
    let i += len(plain)
  endwhile
  return parsed_str
endfunction

function! s:export(cookie) abort
  return {
  \   'name': a:cookie.name(),
  \   'value': a:cookie.value(),
  \   'domain': a:cookie.domain(),
  \   'path': a:cookie.path(),
  \   'creation_time': a:cookie.creation_time().to_string(),
  \   'last_access_time': a:cookie.last_access_time().to_string(),
  \   'attributes': a:cookie.attributes(),
  \ }
endfunction

function! s:import(data) abort
  let cookie = deepcopy(s:Cookie)
  let cookie._name = a:data.name
  let cookie._value = a:data.value
  let cookie._domain = a:data.domain
  let cookie._path = a:data.path
  let cookie._creation_time =
  \   s:DateTime.from_format(a:data.creation_time, '%c')
  let cookie._last_access_time =
  \   s:DateTime.from_format(a:data.last_access_time, '%c')
  let cookie._attributes = a:data.attributes
  return cookie
endfunction



let s:Cookie = {
\   '_attributes': {},
\   '_is_valid': 1,
\ }
function! s:Cookie.name() abort
  return self._name
endfunction

function! s:Cookie.value() abort
  return get(self, '_value', '')
endfunction

function! s:Cookie.expiry_time() abort
  if has_key(self, '_expiry_time')
    return self._expiry_time
  endif
  if has_key(self._attributes, 'Max-Age')
    let max_age = self._attributes['Max-Age']
    if 0 < max_age
      let self._expiry_time = self._creation_time.to(max_age, 'seconds')
    else
      let self._expiry_time = s:DateTime.from_date(0)
    endif
  elseif has_key(self._attributes, 'Expires')
    " TODO: More flexible parsing
    " http://www.hcn.zaq.ne.jp/___/WEB/RFC6265-ja.html#section-5.1.1
    let expires = self._attributes['Expires']
    let format = '%*, %d-%b-%Y %H:%M:%S GMT'
    let time = s:DateTime.from_format(expires, format, 'C')
    let self._expiry_time = time.timezone(0)  " Always GMT
  else
    let self._expiry_time = s:DateTime.from_date(9999, 12, 31, 23, 59, 59)
  endif
  return self._expiry_time
endfunction

function! s:Cookie.domain() abort
  return self._domain
endfunction

function! s:Cookie.path() abort
  return self._path
endfunction

function! s:Cookie.creation_time() abort
  return self._creation_time
endfunction

function! s:Cookie.last_access_time() abort
  return self._last_access_time
endfunction

function! s:Cookie.is_persistent() abort
  return has_key(self._attributes, 'Max-Age') ||
  \     has_key(self._attributes, 'Expires')
endfunction

function! s:Cookie.is_host_only() abort
  return !has_key(self._attributes, 'Domain')
endfunction

function! s:Cookie.is_secure() abort
  return has_key(self._attributes, 'Secure')
endfunction

function! s:Cookie.is_http_only() abort
  return has_key(self._attributes, 'HttpOnly')
endfunction

function! s:Cookie.attributes() abort
  return copy(self._attributes)
endfunction

function! s:Cookie.set_value(value) abort
  let self._value = a:value
endfunction

function! s:Cookie.touch(...) abort
  let self._last_access_time = a:0 ? a:1 : s:DateTime.now()
endfunction

function! s:Cookie.make_cookie_header() abort
  let segments = [self.name() . '=' . self.value()]
  let attrs = self._attributes
  for attr_name in ['Expires', 'Max-Age', 'Domain', 'Path']
    if has_key(attrs, attr_name)
      let segments += [attr_name . '=' . attrs[attr_name]]
    endif
  endfor
  for attr_name in ['Secure', 'HttpOnly']
    if has_key(attrs, attr_name)
      let segments += [attr_name]
    endif
  endfor
  return join(segments, '; ')
endfunction

function! s:Cookie.is_match(url) abort
  let url = type(a:url) == type('') ? s:URI.new(a:url) : a:url
  let domain = tolower(url.host())

  if self.is_host_only()
    if domain !=# self.domain()
      return 0
    endif
  else
    if !s:_is_match_domain(domain, self.domain())
      return 0
    endif
  endif

  if !s:_is_match_path(url.path(), self.path())
    return 0
  endif

  if self.is_secure()
    if url.scheme() !=# 'https'
      return 0
    endif
  endif

  return 1
endfunction

function! s:Cookie.is_expired(...) abort
  if !self.is_persistent()
    return 0
  endif
  let now = a:0 ? a:1 : s:DateTime.now()
  return self.expiry_time().compare(now) < 0
endfunction

function! s:Cookie.is_valid() abort
  return self._is_valid
endfunction


function! s:_is_match_domain(req_domain, cookie_domain) abort
  return a:req_domain ==# a:cookie_domain ||
  \   (s:String.ends_with(a:req_domain, '.' . a:cookie_domain) &&
  \     !s:_is_ip_addr(a:req_domain))
endfunction

function! s:_is_ip_addr(str) abort
  " TODO: IPv6
  return a:str =~# '^\%(\d\+\.\)\{3}\d\+$'
endfunction

function! s:_is_match_path(req_path, cookie_path) abort
  return a:req_path ==# a:cookie_path ||
  \   (stridx(a:req_path, a:cookie_path) == 0 &&
  \     (a:cookie_path =~# '/$' || a:req_path[len(a:cookie_path)] ==# '/'))
endfunction

function! s:_get_default_path(path) abort
  if a:path ==# '' || a:path[0] !=# '/'
    return '/'
  endif
  let last_slash = strridx(a:path, '/')
  if last_slash == 0
    return '/'
  endif
  return a:path[: last_slash - 1]
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
