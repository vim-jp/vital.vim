let s:save_cpo = &cpoptions
set cpoptions&vim

" RFC: http://tools.ietf.org/html/rfc6265
" Japanese Translation: http://www.hcn.zaq.ne.jp/___/WEB/RFC6265-ja.html


function! s:_vital_loaded(V) abort
  let s:URI = a:V.import('Web.URI')
  let s:DateTime = a:V.import('DateTime')
  let s:Cookie = a:V.import('Web.HTTP.Cookie')
endfunction

function! s:_vital_depends() abort
  return ['DateTime', 'Web.URI', 'Web.HTTP.Cookie']
endfunction


function! s:new(...) abort
  let jar = deepcopy(s:Jar)
  if a:0
    call jar.import(a:1)
  endif
  return jar
endfunction

function! s:build_http_header(cookies) abort
  return join(map(copy(a:cookies), 's:_make_cookie_header_entry(v:val)'), '; ')
endfunction


let s:Jar = {
\   '_cookies': {},
\ }

function! s:Jar.add(cookie) abort
  let id = s:_cookie_id(a:cookie)
  let self._cookies[id] = a:cookie
endfunction

function! s:Jar.add_all(cookies) abort
  for cookie in a:cookies
    call self.add(cookie)
  endfor
endfunction

function! s:Jar.add_from_headers(headers, request_uri) abort
  let headers = filter(copy(a:headers), 's:_is_set_cookie_header(v:val)')
  let strings = map(headers, 'matchstr(v:val, "\\c^set-cookie:\\s*\\zs.*")')
  let cookies = map(strings, 's:Cookie.new(v:val, a:request_uri)')
  call self.add_all(cookies)
endfunction

function! s:Jar.get(...) abort
  return get(call(self.get_all, a:000, self), 0, {})
endfunction

function! s:Jar.get_all(...) abort
  let condition = a:0 ? a:1 : {}
  let cookies = values(self._cookies)

  if has_key(condition, 'url')
    let uri = s:URI.new(condition.url)
    if uri is 0
      return []
    endif
    call filter(cookies, 'v:val.is_match(uri)')
  endif

  if has_key(condition, 'name')
    let name = condition.name
    call filter(cookies, 'v:val.name() ==# name')
  endif

  if has_key(condition, 'name_pattern')
    let pattern = condition.name_pattern
    call filter(cookies, 'v:val.name() =~# pattern')
  endif

  if has_key(condition, 'expired')
    let expired = !!condition.expired
    call filter(cookies, 'v:val.is_expired() == expired')
  endif

  if has_key(condition, 'valid')
    let valid = !!condition.valid
    call filter(cookies, 'v:val.is_valid() == valid')
  endif

  return cookies
endfunction

function! s:Jar.build_http_header(url, ...) abort
  let condition = {
  \   'url': a:url,
  \   'expired': 0,
  \   'valid': 1,
  \ }
  let cookies = self.get_all(condition)
  let dry_run = a:0 && a:1
  if !dry_run
    let now = s:DateTime.now()
    for cookie in cookies
      call cookie.touch(now)
    endfor
  endif
  return s:build_http_header(cookies)
endfunction

function! s:Jar.sweep_expired(...) abort
  let now = a:0 ? a:1 : s:DateTime.now()
  call filter(self._cookies, '!v:val.is_expired(now)')
endfunction

function! s:Jar.clear() abort
  let self._cookies = {}
endfunction

function! s:Jar.export(...) abort
  let all = a:0 && a:1
  let cookies = self.get_all()
  if !all
    call filter(cookies, 'v:val.is_persistent()')
  endif
  return {
  \   'cookies': map(cookies, 's:Cookie.export(v:val)'),
  \ }
endfunction

function! s:Jar.import(data) abort
  let cookies = map(copy(a:data.cookies), 's:Cookie.import(v:val)')
  call self.add_all(cookies)
endfunction


function! s:_make_cookie_header_entry(cookie) abort
  let name = s:URI.encode(a:cookie.name())
  let value = s:URI.encode(a:cookie.value())
  return printf('%s=%s', name, value)
endfunction

function! s:_is_set_cookie_header(header) abort
  return a:header =~? '^set-cookie: '
endfunction

function! s:_cookie_id(cookie) abort
  return join([a:cookie.domain(), a:cookie.path(), a:cookie.name()], "\n")
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
