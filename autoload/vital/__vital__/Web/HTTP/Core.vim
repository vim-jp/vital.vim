let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Prelude = s:V.import('Prelude')
  let s:Process = s:V.import('Process')
  let s:String = s:V.import('Data.String')
endfunction

function! s:_vital_depends() abort
   return {
    \ 'modules':['Prelude', 'Data.String', 'Process'] ,
    \ 'files':  ['HTTP_python2.py', 'HTTP_python3.py'],
    \}
endfunction

function! s:__urlencode_char(c) abort
  return printf('%%%02X', char2nr(a:c))
endfunction

function! s:readfile(file) abort
  if filereadable(a:file)
    return join(readfile(a:file, 'b'), "\n")
  endif
  return ''
endfunction

function! s:make_postfile(data) abort
  let fname = s:tempname()
  call writefile(a:data, fname, 'b')
  return fname
endfunction

function! s:tempname() abort
  return s:file_resolve(tempname())
endfunction

function! s:file_resolve(file) abort
  return fnamemodify(a:file, ':p:gs?\\?/?')
endfunction

function! s:postdata(data) abort
  if s:Prelude.is_dict(a:data)
    return [s:encodeURI(a:data)]
  elseif s:Prelude.is_list(a:data)
    return a:data
  else
    return split(a:data, "\n")
  endif
endfunction

function! s:build_response(header, content) abort
  let response = {
  \   'header' : a:header,
  \   'content': a:content,
  \   'status': 0,
  \   'statusText': '',
  \   'success': 0,
  \ }

  if !empty(a:header)
    let status_line = get(a:header, 0)
    let matched = matchlist(status_line, '^HTTP/\%(1\.\d\|2\)\s\+\(\d\+\)\s\+\(.*\)')
    if !empty(matched)
      let [status, status_text] = matched[1 : 2]
      let response.status = status - 0
      let response.statusText = status_text
      let response.success = status =~# '^2'
      call remove(a:header, 0)
    endif
  endif
  return response
endfunction

function! s:build_last_response(responses) abort
  let all_headers = []
  for response in a:responses
    call extend(all_headers, response.header)
  endfor
  let last_response = remove(a:responses, -1)
  let last_response.redirectInfo = a:responses
  let last_response.allHeaders = all_headers
  return last_response
endfunction

function! s:build_settings(args) abort
  let settings = {
  \   'method': 'GET',
  \   'headers': {},
  \   'client': ['python', 'curl', 'wget', 'python3', 'python2'],
  \   'maxRedirect': 20,
  \   'retry': 1,
  \ }
  let args = copy(a:args)
  if len(args) == 0
    throw 'vital: Web.HTTP: request() needs one or more arguments.'
  endif
  if s:Prelude.is_dict(args[-1])
    call extend(settings, remove(args, -1))
  endif
  if len(args) == 2
    let settings.method = remove(args, 0)
  endif
  if !empty(args)
    let settings.url = args[0]
  endif

  return settings
endfunction

function! s:make_header_args(headdata, option, quote) abort
  let args = ''
  for [key, value] in items(a:headdata)
    if s:Prelude.is_windows()
      let value = substitute(value, '"', '"""', 'g')
    endif
    let args .= ' ' . a:option . a:quote . key . ': ' . value . a:quote
  endfor
  return args
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

function! s:quote() abort
  return &shell =~# 'sh$' ? "'" : '"'
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
