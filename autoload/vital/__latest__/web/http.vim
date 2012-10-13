let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#{expand('<sfile>:h:h:t:r')}#new()

function! s:_vital_depends()
  return ['Data.String', 'Prelude']
endfunction

let s:prelude = s:V.import('Prelude')
let s:string = s:V.import('Data.String')

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
  if s:prelude.is_dict(a:items)
    for key in sort(keys(a:items))
      if strlen(ret) | let ret .= "&" | endif
      let ret .= key . "=" . s:encodeURI(a:items[key])
    endfor
  elseif s:prelude.is_list(a:items)
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
  if s:prelude.is_dict(a:items)
    for key in sort(keys(a:items))
      if strlen(ret) | let ret .= "&" | endif
      let ret .= key . "=" . s:encodeURIComponent(a:items[key])
    endfor
  elseif s:prelude.is_list(a:items)
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
        let ret .= '%' . substitute('0' . s:string.nr2hex(char2nr(ch)), '^.*\(..\)$', '\1', '')
      endif
      let i = i + 1
    endwhile
  endif
  return ret
endfunction

function! s:request(...)
  let settings = {}
  for arg in a:000
    if s:prelude.is_dict(arg)
      let settings = extend(settings, arg, 'keep')
    elseif s:prelude.is_string(arg)
      if has_key(settings, 'url')
        let settings.method = settings.url
      endif
      let settings.url = arg
    endif
    unlet arg
  endfor
  let url = get(settings, 'url', '')
  let method = toupper(get(settings, 'method', 'GET'))
  let headers = get(settings, 'headers', {})
  let quote = &shellxquote == '"' ?  "'" : '"'
  if has_key(settings, 'param')
    let getdatastr = s:encodeURI(settings.param)
    if strlen(getdatastr)
      let url .= '?' . getdatastr
    endif
  endif
  let has_data = has_key(settings, 'data')
  if has_data
    if s:prelude.is_dict(settings.data)
      let postdatastr = s:encodeURI(settings.data)
    else
      let postdatastr = settings.data
    endif
    let file = tempname()
    call writefile(split(postdatastr, "\n"), file, "b")
  endif
  if executable('curl')
    let command = 'curl -L -s -k -i -X ' . method
    let command .= s:_make_header_args(headers, '-H ', quote)
    let command .= ' ' . quote . url . quote
    if has_data
      let command .= ' --data-binary @' . quote . file . quote
    endif
    let res = s:prelude.system(command)
  elseif executable('wget')
    let headers['X-HTTP-Method-Override'] = method
    let command = 'wget -O- --save-headers --server-response -q -L '
    let command .= s:_make_header_args(headers, '--header=', quote)
    let command .= ' ' . quote . url . quote
    if has_data
      let command .= ' --post-data @' . quote . file . quote
    endif
    let res = s:prelude.system(command)
  endif
  if has_data
    call delete(file)
  endif
  return s:_build_response(res)
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
  if res =~# '^HTTP/1.\d [13]' || res =~# '^HTTP/1\.\d 200 Connection established'
    let pos = stridx(res, "\r\n\r\n")
    if pos != -1
      let res = res[pos + 4 :]
    else
      let pos = stridx(res, "\n\n")
      let res = res[pos + 2 :]
    endif
  endif
  let pos = stridx(res, "\r\n\r\n")
  if pos != -1
    let content = res[pos + 4 :]
  else
    let pos = stridx(res, "\n\n")
    let content = res[pos + 2 :]
  endif
  return {
  \   'header' : split(res[: pos - 1], '\r\?\n'),
  \   'content': content
  \ }
endfunction

function! s:_make_header_args(headdata, option, quote)
  let args = ''
  for [key, value] in items(a:headdata)
    if s:prelude.is_windows()
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
