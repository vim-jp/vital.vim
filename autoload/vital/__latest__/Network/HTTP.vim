let s:save_cpo = &cpo
set cpo&vim

let s:registry = {}
let s:priority = []

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Prelude = a:V.import('Prelude')
  let s:Dict = a:V.import('Data.Dict')
  let s:String = a:V.import('Data.String')

  call s:register('Network.HTTP.Python', 'python')
endfunction
function! s:_vital_depends() abort
  return [
        \ 'Prelude',
        \ 'Data.Dict',
        \ 'Data.String',
        \ 'Network.HTTP.Python',
        \]
endfunction

function! s:_throw(msg) abort
  throw printf('vital: Network.HTTP: %s', a:msg)
endfunction
function! s:_get_default_request() abort
  return {
        \ 'method': 'GET',
        \ 'data': '',
        \ 'headers': {},
        \ 'output_file': '',
        \ 'timeout': 0,
        \ 'realm': '',
        \ 'username': '',
        \ 'password': '',
        \ 'max_redirect': 20,
        \ 'retry': 1,
        \ 'auth_method': '',
        \ 'gzip_decompress': 0,
        \ 'insecure': 0,
        \}
endfunction
function! s:__urlencode_char(c) abort
  return printf('%%%02X', char2nr(a:c))
endfunction

function! s:register(name, ...) abort
  let alias = get(a:000, 0, a:name)
  let s:registry[alias] = s:V.import(a:name)
  call add(s:priority, alias)
endfunction

function! s:decodeURI(str) abort
  let ret = a:str
  let ret = substitute(ret, '+', ' ', 'g')
  let ret = substitute(ret, '%\(\x\x\)', '\=printf("%c", str2nr(submatch(1), 16))', 'g')
  return ret
endfunction
function! s:escape(str) abort
  let result = ''
  for i in range(len(a:str))
    if a:str[i] =~# '^[a-zA-Z0-9_.~-]$'
      let result .= a:str[i]
    else
      let result .= s:__urlencode_char(a:str[i])
    endif
  endfor
  return result
endfunction
function! s:encodeURI(items) abort
  let ret = ''
  if s:Prelude.is_dict(a:items)
    for key in sort(keys(a:items))
      if strlen(ret)
        let ret .= '&'
      endif
      let ret .= key . '=' . s:encodeURI(a:items[key])
    endfor
  elseif s:Prelude.is_list(a:items)
    for item in sort(a:items)
      if strlen(ret)
        let ret .= '&'
      endif
      let ret .= item
    endfor
  else
    let ret = s:escape(a:items)
  endif
  return ret
endfunction
function! s:encodeURIComponent(items) abort
  let ret = ''
  if s:Prelude.is_dict(a:items)
    for key in sort(keys(a:items))
      if strlen(ret) | let ret .= '&' | endif
      let ret .= key . '=' . s:encodeURIComponent(a:items[key])
    endfor
  elseif s:Prelude.is_list(a:items)
    for item in sort(a:items)
      if strlen(ret) | let ret .= '&' | endif
      let ret .= item
    endfor
  else
    let items = iconv(a:items, &enc, 'utf-8')
    let len = strlen(items)
    let i = 0
    while i < len
      let ch = items[i]
      if ch =~# '[0-9A-Za-z-._~!''()*]'
        let ret .= ch
      elseif ch ==# ' '
        let ret .= '+'
      else
        let ret .= '%' . substitute('0' . s:String.nr2hex(char2nr(ch)), '^.*\(..\)$', '\1', '')
      endif
      let i = i + 1
    endwhile
  endif
  return ret
endfunction

function! s:build_request(request) abort
  let request = extend({
        \ 'method': 'GET',
        \ 'params': {},
        \ 'data': '',
        \ 'headers': {},
        \ 'content_type': '',
        \ 'output_file': '',
        \ 'timeout': 0,
        \ 'realm': '',
        \ 'username': '',
        \ 'password': '',
        \ 'max_redirect': 20,
        \ 'retry': 1,
        \ 'auth_method': '',
        \ 'gzip_decompress': 0,
        \ 'insecure': 0,
        \}, a:request
        \)
  if !has_key(request, 'url')
    call s:_throw('"url" parameter is required')
  endif

  if !empty(request.content_type)
    let request.headers['Content-Type'] = request.content_type
  endif
  if !empty(request.params)
    let param = s:encodeURI(request.params)
    if strlen(param)
      let request.url = printf('%s?%s', request.url, param)
    endif
  endif
  if !empty(request.data)
    if s:Prelude.is_dict(request.data)
      let data = [s:encodeURI(request.data)]
    elseif s:Prelude.is_list(request.data)
      let data = request.data
    else
      " XXX: Use System.Process.split_posix_text instead
      let data = split(request.data, '\r\?\n', 1)
    endif
    unlet! request.data
    let request.data = data
    let request.headers['Content-Length'] = len(join(request.data, "\n"))
  endif
  if request.gzip_decompress
    let request.headers['Accept-encoding'] = 'gzip'
  endif
  return s:Dict.pick(request, [
        \ 'url',
        \ 'method',
        \ 'data',
        \ 'headers',
        \ 'output_file',
        \ 'timeout',
        \ 'realm',
        \ 'username',
        \ 'password',
        \ 'max_redirect',
        \ 'retry',
        \ 'auth_method',
        \ 'gzip_decompress',
        \ 'insecure',
        \])
endfunction
function! s:build_response(response) abort
  let response = extend({
        \ 'raw_status': 'HTTP/1.1 500 Internal Server Error',
        \ 'raw_headers': '',
        \ 'raw_content': '',
        \}, a:response)
  let response.headers = {}
  for header in split(response.raw_headers, '\r\?\n')
    let m = matchlist(header, '^\([^:]\+\): \(.*\)$')
    if len(m) > 0
      let response.headers[m[1]] = m[2]
    endif
  endfor
  " XXX: Use System.Process.split_posix_text instead
  let response.content = split(response.raw_content, '\r\?\n', 1)
  let response.version = matchstr(
        \ response.raw_status,
        \ 'HTTP/\zs1\.[01]'
        \)
  let response.status = str2nr(matchstr(
        \ response.raw_status,
        \ 'HTTP/1\.[01] \zs\d\+'
        \))
  let response.status_text = matchstr(
        \ response.raw_status,
        \ 'HTTP/1\.[01] \d\+ \zs.*$'
        \)
  let response.success = ('' . response.status) =~# '^2'
  return response
endfunction

" request({config})
" request({url}[, {config}])
" request({method}, {url}[, {config}])
function! s:request(...) abort
  if a:0 == 0
    call s:_throw('request() require at least one argument')
  elseif a:0 == 1
    if s:Prelude.is_string(a:1)
      " config({url})
      let config = {}
      let config.url = a:1
    else
      " config({config})
      let config = a:1
    endif
  elseif a:0 == 2
    if s:Prelude.is_string(a:2)
      " config({method}, {url})
      let config = {}
      let config.url = a:2
      let config.method = a:1
    else
      " config({url}, {config})
      let config = a:2
      let config.url = a:1
    endif
  elseif a:0 == 3
    " config({method}, {url}, {config})
    let config = a:3
    let config.url = a:2
    let config.method = a:1
  else
    call s:_throw('The maximum number of arguments of request() is 3')
  endif
  return s:build_request(config)
endfunction

" open({request}[, {settings}])
function! s:open(request, ...) abort
  let request = extend(
        \ s:_get_default_request(),
        \ a:request,
        \)
  let settings = extend({
        \ 'clients': s:priority,
        \}, get(a:000, 0, {})
        \)
  for alias in settings.clients
    let client = s:registry[alias]
    if !client.is_open_supported(request)
      continue
    endif
    return s:build_response(client.open(request, settings))
  endfor
  call s:_throw('Not supported')
endfunction

" open_async({request}[, {settings}])
function! s:open_async(request, ...) abort
  let request = extend(
        \ s:_get_default_request(),
        \ a:request,
        \)
  let settings = extend({
        \ 'clients': s:priority,
        \}, get(a:000, 0, {})
        \)
  for alias in settings.clients
    let client = s:registry[alias]
    if !client.is_open_async_supported(request)
      continue
    endif
    return client.open_async(request, settings)
  endfor
  call s:_throw('Not supported')
endfunction

let &cpo = s:save_cpo
unlet! s:save_cpo
" vim:set et ts=2 sts=2 sw=2 tw=0 fdm=marker:

