let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Prelude = s:V.import('Prelude')
  let s:AsyncProcess = s:V.import('System.AsyncProcess')
  let s:String = s:V.import('Data.String')
  let s:Core = s:V.import('Web.HTTP.Core')
endfunction

function! s:_vital_depends() abort
   return {
    \ 'modules':['Prelude', 'Data.String', 'System.AsyncProcess'] ,
    \}
endfunction

function! s:decodeURI(str) abort
  return s:Core.decodeURI(a:str)
endfunction

function! s:encodeURI(items) abort
  return s:Core.encodeURI(a:items)
endfunction

function! s:encodeURIComponent(items) abort
  return s:Core.encodeURIComponent(a:items)
endfunction

function! s:_request_cb(settings, responses, exit_code) abort
  for file in values(a:settings._file)
    if filereadable(file)
      call delete(file)
    endif
  endfor

  call map(a:responses, 's:Core.build_response(v:val[0], v:val[1])')
  let last_response = s:Core.build_last_response(a:responses)
  if has_key(a:settings, 'user_cb')
    call a:settings.user_cb(last_response)
  endif
endfunction

function! s:request(...) abort
  let settings = s:Core.build_settings(a:000)
  let settings.method = toupper(settings.method)
  if !has_key(settings, 'url')
    throw 'vital: Web.HTTP: "url" parameter is required.'
  endif
  if !s:Prelude.is_list(settings.client)
    let settings.client = [settings.client]
  endif
  let client = s:_get_client(settings)
  if empty(client)
    throw 'vital: Web.HTTP: Available client not found: '
    \    . string(settings.client)
  endif
  if has_key(settings, 'contentType')
    let settings.headers['Content-Type'] = settings.contentType
  endif
  if has_key(settings, 'param')
    if s:Prelude.is_dict(settings.param)
      let getdatastr = s:encodeURI(settings.param)
    else
      let getdatastr = settings.param
    endif
    if strlen(getdatastr)
      let settings.url .= '?' . getdatastr
    endif
  endif
  if has_key(settings, 'data')
    let settings.data = s:Core.postdata(settings.data)
    let settings.headers['Content-Length'] = len(join(settings.data, "\n"))
  endif
  let settings._file = {}

  let responses = client.request(settings)
endfunction

function! s:get(url, ...) abort
  let settings = {
  \    'url': a:url,
  \    'param': a:0 > 0 ? a:1 : {},
  \    'headers': a:0 > 1 ? a:2 : {},
  \ }
  return s:request(settings)
endfunction

function! s:post(url, ...) abort
  let settings = {
  \    'url': a:url,
  \    'data': a:0 > 0 ? a:1 : {},
  \    'headers': a:0 > 1 ? a:2 : {},
  \    'method': a:0 > 2 ? a:3 : 'POST',
  \ }
  return s:request(settings)
endfunction

function! s:parseHeader(headers) abort
  return c:Core.parseHeader(a:headers)
endfunction

" Clients
function! s:_get_client(settings) abort
  for name in a:settings.client
    if has_key(s:clients, name) && s:clients[name].available(a:settings)
      return s:clients[name]
    endif
  endfor
  return {}
endfunction

" implements clients
let s:clients = {}

let s:clients.curl = {}

function! s:clients.curl.available(settings) abort
  return executable(self._command(a:settings))
endfunction

function! s:clients.curl._command(settings) abort
  return get(get(a:settings, 'command', {}), 'curl', 'curl')
endfunction

function! s:_curl_cb(has_output_file, output_file, settings, exit_code) abort
  let headerstr = s:Core.readfile(a:settings._file.header)
  let header_chunks = split(headerstr, "\r\n\r\n")
  let headers = map(header_chunks, 'split(v:val, "\r\n")')

  call s:Core.curl_validate_retcode(headers, a:exit_code)

  if !empty(headers)
    let responses = map(headers, '[v:val, ""]')
  else
    let responses = [[[], '']]
  endif
  if a:has_output_file || a:settings.method ==? 'HEAD'
    let content = ''
  else
    let content = s:Core.readfile(a:output_file)
  endif
  let responses[-1][1] = content

  return s:_request_cb(a:settings, responses, a:exit_code)
endfunction

function! s:clients.curl.request(settings) abort
  let quote = '"'
  let command = self._command(a:settings)
  if has_key(a:settings, 'unixSocket')
    let command .= ' --unix-socket ' . quote . a:settings.unixSocket . quote
  endif
  let a:settings._file.header = s:Core.tempname()
  let command .= ' --dump-header ' . quote . a:settings._file.header . quote
  let has_output_file = has_key(a:settings, 'outputFile')
  if has_output_file
    let output_file = s:Core.file_resolve(a:settings.outputFile)
  else
    let output_file = s:Core.tempname()
    let a:settings._file.content = output_file
  endif
  let command .= ' --output ' . quote . output_file . quote
  if has_key(a:settings, 'gzipDecompress') && a:settings.gzipDecompress
    let command .= ' --compressed '
  endif
  let command .= ' -L -s -k '
  if a:settings.method ==? 'HEAD'
    let command .= '--head'
  else
    let command .= '-X ' . a:settings.method
  endif
  let command .= ' --max-redirs ' . a:settings.maxRedirect
  let command .= s:Core.make_header_args(a:settings.headers, '-H ', quote)
  let timeout = get(a:settings, 'timeout', '')
  let command .= ' --retry ' . a:settings.retry
  if timeout =~# '^\d\+$'
    let command .= ' --max-time ' . timeout
  endif
  if has_key(a:settings, 'username')
    let auth = a:settings.username . ':' . get(a:settings, 'password', '')
    let auth = escape(auth, quote)
    if has_key(a:settings, 'authMethod')
      if index(['basic', 'digest', 'ntlm', 'negotiate'], a:settings.authMethod) == -1
        throw 'vital: Web.HTTP: Invalid authorization method: ' . a:settings.authMethod
      endif
      let method = a:settings.authMethod
    else
      let method = 'anyauth'
    endif
    let command .= ' --' . method . ' --user ' . quote . auth . quote
  endif
  if has_key(a:settings, 'bearerToken')
        \ && has_key(a:settings, 'authMethod') && (a:settings.authMethod ==? 'oauth2')
    let command .= ' --oauth2-bearer '  . quote . a:settings.bearerToken . quote
  endif
  if has_key(a:settings, 'data')
    let a:settings._file.post = s:Core.make_postfile(a:settings.data)
    let command .= ' --data-binary @' . quote . a:settings._file.post . quote
  endif
  let command .= ' ' . quote . a:settings.url . quote

  call s:AsyncProcess.execute(command, {
        \ 'exit_cb': function('s:_curl_cb', [has_output_file, output_file, a:settings])})
endfunction

let s:clients.wget = {}

function! s:clients.wget.available(settings) abort
  if has_key(a:settings, 'authMethod')
    return 0
  endif
  return executable(self._command(a:settings))
endfunction

function! s:clients.wget._command(settings) abort
  return get(get(a:settings, 'command', {}), 'wget', 'wget')
endfunction

function! s:_wget_cb(has_output_file, output_file, settings, exit_code) abort
  if filereadable(a:settings._file.header)
    let header_lines = readfile(a:settings._file.header, 'b')
    call map(header_lines, 'matchstr(v:val, "^\\s*\\zs.*")')
    let headerstr = join(header_lines, "\r\n")
    let header_chunks = split(headerstr, '\r\n\zeHTTP/\%(1\.\d\|2\)')
    let headers = map(header_chunks, 'split(v:val, "\r\n")')
    let responses = map(headers, '[v:val, ""]')
  else
    let headers = []
    let responses = [[[], '']]
  endif

  call s:Core.wget_validate_retcode(headers, a:exit_code)

  if a:has_output_file
    let content = ''
  else
    let content = s:Core.readfile(a:output_file)
  endif
  let responses[-1][1] = content

  return s:_request_cb(a:settings, responses, a:exit_code)
endfunction

function! s:clients.wget.request(settings) abort
  if has_key(a:settings, 'unixSocket')
    throw 'vital: Web.HTTP: unixSocket only can be used with the curl.'
  endif
  let quote = '"'
  let command = self._command(a:settings)
  let method = a:settings.method
  if method ==# 'HEAD'
    let command .= ' --spider'
  elseif method !=# 'GET' && method !=# 'POST'
    let a:settings.headers['X-HTTP-Method-Override'] = a:settings.method
  endif
  let a:settings._file.header = s:Core.tempname()
  let command .= ' -o ' . quote . a:settings._file.header . quote
  let has_output_file = has_key(a:settings, 'outputFile')
  if has_output_file
    let output_file = s:Core.file_resolve(a:settings.outputFile)
  else
    let output_file = s:Core.tempname()
    let a:settings._file.content = output_file
  endif
  let command .= ' -O ' . quote . output_file . quote
  let command .= ' --server-response -q -L '
  let command .= ' --max-redirect=' . a:settings.maxRedirect
  let command .= s:Core.make_header_args(a:settings.headers, '--header=', quote)
  let timeout = get(a:settings, 'timeout', '')
  let command .= ' --tries=' . a:settings.retry
  if timeout =~# '^\d\+$'
    let command .= ' --timeout=' . timeout
  endif
  if has_key(a:settings, 'username')
    let command .= ' --http-user=' . quote . escape(a:settings.username, quote) . quote
  endif
  if has_key(a:settings, 'password')
    let command .= ' --http-password=' . quote . escape(a:settings.password, quote) . quote
  endif
  if has_key(a:settings, 'bearerToken')
    let command .= ' --header=' . quote . 'Authorization: Bearer ' . a:settings.bearerToken . quote
  endif
  let command .= ' ' . quote . a:settings.url . quote
  if has_key(a:settings, 'data')
    let a:settings._file.post = s:Core.make_postfile(a:settings.data)
    let command .= ' --post-file=' . quote . a:settings._file.post . quote
  endif

  call s:AsyncProcess.execute(command, {'exit_cb': function('s:_wget_cb', [has_output_file, output_file, a:settings])})
endfunction


function! s:_quote() abort
  return &shell =~# 'sh$' ? "'" : '"'
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:

