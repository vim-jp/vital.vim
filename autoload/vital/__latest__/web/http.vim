let s:save_cpo = &cpo
set cpo&vim


function! s:_vital_loaded(V)
  let s:V = a:V

  let s:Prelude = s:V.import('Prelude')
  let s:String = s:V.import('Data.String')
endfunction

function! s:_vital_depends()
  return ['Data.String', 'Prelude']
endfunction

function! s:__urlencode_char(c)
  let utf = iconv(a:c, &encoding, "utf-8")
  if utf == ""
    let utf = a:c
  endif
  let s = ""
  for i in range(strlen(utf))
    let s .= printf("%%%02X", char2nr(utf[i]))
  endfor
  return s
endfunction

function! s:decodeURI(str)
  let ret = a:str
  let ret = substitute(ret, '+', ' ', 'g')
  let ret = substitute(ret, '%\(\x\x\)', '\=printf("%c", str2nr(submatch(1), 16))', 'g')
  return ret
endfunction

function! s:escape(str)
  return substitute(a:str, '[^a-zA-Z0-9_.~/-]', '\=s:__urlencode_char(submatch(0))', 'g')
endfunction

function! s:encodeURI(items)
  let ret = ''
  if s:Prelude.is_dict(a:items)
    for key in sort(keys(a:items))
      if strlen(ret) | let ret .= "&" | endif
      let ret .= key . "=" . s:encodeURI(a:items[key])
    endfor
  elseif s:Prelude.is_list(a:items)
    for item in sort(a:items)
      if strlen(ret) | let ret .= "&" | endif
      let ret .= item
    endfor
  else
    let ret = substitute(a:items, '[^a-zA-Z0-9_.~-]', '\=s:__urlencode_char(submatch(0))', 'g')
  endif
  return ret
endfunction

function! s:encodeURIComponent(items)
  let ret = ''
  if s:Prelude.is_dict(a:items)
    for key in sort(keys(a:items))
      if strlen(ret) | let ret .= "&" | endif
      let ret .= key . "=" . s:encodeURIComponent(a:items[key])
    endfor
  elseif s:Prelude.is_list(a:items)
    for item in sort(a:items)
      if strlen(ret) | let ret .= "&" | endif
      let ret .= item
    endfor
  else
    let items = iconv(a:items, &enc, "utf-8")
    let len = strlen(items)
    let i = 0
    while i < len
      let ch = items[i]
      if ch =~# '[0-9A-Za-z-._~!''()*]'
        let ret .= ch
      elseif ch == ' '
        let ret .= '+'
      else
        let ret .= '%' . substitute('0' . s:String.nr2hex(char2nr(ch)), '^.*\(..\)$', '\1', '')
      endif
      let i = i + 1
    endwhile
  endif
  return ret
endfunction

let s:default_settings = {
\   'method': 'GET',
\   'headers': {},
\   'client': executable('curl') ? 'curl' :
\             executable('wget') ? 'wget' : '',
\ }
function! s:request(...)
  let settings = {}
  for arg in a:000
    if s:Prelude.is_dict(arg)
      let settings = extend(settings, arg, 'keep')
    elseif s:Prelude.is_string(arg)
      if has_key(settings, 'url')
        let settings.method = settings.url
      endif
      let settings.url = arg
    endif
    unlet arg
  endfor
  call extend(settings, s:default_settings, 'keep')
  if !has_key(settings, 'url')
    throw 'Vital.Web.Http.request(): "url" parameter is required.'
  endif
  if !has_key(s:command_builders, settings.client)
    throw 'Vital.Web.Http.request(): Unknown client "' . settings.client . "'"
  endif
  if has_key(settings, 'contentType')
    let settings.headers['Content-Type'] = settings.contentType
  endif
  if has_key(settings, 'param')
    let getdatastr = s:encodeURI(settings.param)
    if strlen(getdatastr)
      let settings.url .= '?' . getdatastr
    endif
  endif
  if has_key(settings, 'data')
    if s:Prelude.is_dict(settings.data)
      let postdatastr = s:encodeURI(settings.data)
    else
      let postdatastr = settings.data
    endif
    let settings._file = tempname()
    call writefile(split(postdatastr, "\n"), settings._file, "b")
  endif

  let quote = &shellxquote == '"' ?  "'" : '"'
  let command = s:command_builders[settings.client](settings, quote)
  let res = s:Prelude.system(command)

  if has_key(settings, '_file')
    call delete(settings._file)
  endif
  return s:_build_response(res)
endfunction

let s:command_builders = {}
function! s:command_builders.curl(settings, quote)
  let command = get(a:settings, 'command', 'curl')
  let command .= ' -L -s -k -i -X ' . a:settings.method
  let command .= s:_make_header_args(a:settings.headers, '-H ', a:quote)
  let timeout = get(a:settings, 'timeout', '')
  if timeout =~# '^\d\+$'
    let command .= ' --max-time ' . timeout
  endif
  if has_key(a:settings, 'username')
    let auth = a:settings.username
    if has_key(a:settings, 'password')
      let auth .= ':' . a:settings.password
    endif
    let command .= ' --anyauth --user ' . a:quote . auth . a:quote
  endif
  let command .= ' ' . a:quote . a:settings.url . a:quote
  if has_key(a:settings, '_file')
    let command .= ' --data-binary @' . a:quote . a:settings._file . a:quote
  endif
  return command
endfunction
function! s:command_builders.wget(settings, quote)
  let command = get(a:settings, 'command', 'wget')
  let method = a:settings.method
  if method ==# 'HEAD'
    let command .= ' --spider'
  elseif method !=# 'GET' && method !=# 'POST'
    let a:settings.headers['X-HTTP-Method-Override'] = a:settings.method
  endif
  let command .= ' -O- --save-headers --server-response -q -L '
  let command .= s:_make_header_args(a:settings.headers, '--header=', a:quote)
  let timeout = get(a:settings, 'timeout', '')
  if timeout =~# '^\d\+$'
    let command .= ' --timeout=' . timeout
  endif
  if has_key(a:settings, 'username')
    let command .= ' --http-user ' . a:quote . a:settings.username . a:quote
  endif
  if has_key(a:settings, 'password')
    let command .= ' --http-password ' . a:quote . a:settings.password . a:quote
  endif
  let command .= ' ' . a:quote . a:settings.url . a:quote
  if has_key(a:settings, '_file')
    let command .= ' --post-data @' . a:quote . a:settings._file . a:quote
  endif
  return command
endfunction

function! s:get(url, ...)
  let settings = {
  \    'url': a:url,
  \    'param': a:0 > 0 ? a:1 : {},
  \    'headers': a:0 > 1 ? a:2 : {},
  \ }
  return s:request(settings)
endfunction

function! s:post(url, ...)
  let settings = {
  \    'url': a:url,
  \    'data': a:0 > 0 ? a:1 : {},
  \    'headers': a:0 > 1 ? a:2 : {},
  \    'method': a:0 > 2 ? a:3 : 'POST',
  \ }
  return s:request(settings)
endfunction

function! s:_build_response(res)
  let res = a:res
  if res =~# '^\s'
    " wget returns extra headers with indention
    " when redirected or authenticated
    let pos = match(res, '\n\zs\S')
    if 0 <= pos
      let res = res[pos :]
    endif
  endif
  while res =~# '^HTTP/1.\d \%([13]\|401\)' ||
  \     res =~# '^HTTP/1\.\d 200 Connection established'
    let pos = stridx(res, "\r\n\r\n")
    if pos != -1
      let res = res[pos + 4 :]
    else
      let pos = stridx(res, "\n\n")
      let res = res[pos + 2 :]
    endif
  endwhile
  let pos = stridx(res, "\r\n\r\n")
  if pos != -1
    let content = res[pos + 4 :]
  else
    let pos = stridx(res, "\n\n")
    let content = res[pos + 2 :]
  endif

  let header = split(res[: pos - 1], '\r\?\n')
  let response = {
  \   'header' : header,
  \   'content': content,
  \ }

  let matched = matchlist(header[0], '^HTTP/1\.\d\s\+\(\d\+\)\s\+\(.*\)')
  if !empty(matched)
    let [status, statusText] = matched[1 : 2]
    let response.status = status - 0
    let response.statusText = statusText
    let response.success = status =~# '^2'
  endif
  return response
endfunction

function! s:_make_header_args(headdata, option, quote)
  let args = ''
  for [key, value] in items(a:headdata)
    if s:Prelude.is_windows()
      let value = substitute(value, '"', '"""', 'g')
    endif
    let args .= " " . a:option . a:quote . key . ": " . value . a:quote
  endfor
  return args
endfunction

function! s:parseHeader(headers)
  " FIXME: User should be able to specify the treatment method of the duplicate item.
  let header = {}
  for h in a:headers
    let matched = matchlist(h, '^\([^:]\+\):\s*\(.*\)$')
    if !empty(matched)
      let [name, value] = matched[1 : 2]
      let header[name] = value
    endif
  endfor
  return header
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
