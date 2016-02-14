let s:save_cpo = &cpo
set cpo&vim
let s:script_root = expand('<sfile>:p:h')

function! s:_vital_loaded(V) abort
  let s:Prelude = a:V.import('Prelude')
  let s:Path = a:V.import('System.Filepath')
  let s:Python = a:V.import('Vim.Python')
endfunction
function! s:_vital_depends() abort
  return ['Prelude', 'System.Filepath', 'Vim.Python']
endfunction

function! s:_throw(msg) abort
  throw printf('vital: Network.HTTP.Python: %s', a:msg)
endfunction

function! s:is_open_supported(request) abort
  return 1
endfunction

function! s:open(request, settings) abort
  let settings = extend({
        \ 'python': 0,
        \}, a:settings)
  let python = settings.python == 1 ? 0 : settings.python
  let prefix = '_vital_vim_network_http'
  let code = [
        \ 'import vim',
        \ printf(
        \   'from _vital_vim_network_http import urlopen_from_vim as %s_urlopen',
        \   prefix,
        \ ),
        \ printf(
        \   '%s_urlopen_result = %s_urlopen(vim.eval("a:request"))',
        \   prefix, prefix,
        \ ),
        \]
  call s:Python.add_pythonpath(s:Path.join(s:script_root, 'Python'))
  execute s:Python.exec_code(code, python)
  " NOTE:
  " To support neovim, bindeval cannot be used for now.
  " That's why eval_expr is required to call separatly
  let response = s:Python.eval_expr('_vital_vim_network_http_urlopen_result')
  let code = [
        \ printf('del %s_urlopen', prefix),
        \ printf('del %s_urlopen_result', prefix),
        \]
  execute s:Python.exec_code(code, python)
  if s:Prelude.is_string(response)
    call s:_throw(response)
  endif
  let [url, headers, body] = response
  return {
        \ 'url': url,
        \ 'raw_headers': headers,
        \ 'raw_content': body,
        \}
endfunction

function! s:is_open_async_supported(request) abort
  return 0
endfunction

function! s:open_async(request, settings) abort
  throw s:_throw('Async open is not supported')
endfunction

let &cpo = s:save_cpo
unlet! s:save_cpo
" vim:set et ts=2 sts=2 sw=2 tw=0 fdm=marker:

