let s:save_cpoptions = &cpoptions
set cpoptions&vim

function! s:_vital_loaded(V) abort
  let s:Prelude = a:V.import('Prelude')
endfunction
function! s:_vital_depends() abort
  return [
        \ 'Prelude',
        \]
endfunction

function! s:is_available() abort
  if exists('s:vimproc_available')
    return s:vimproc_available
  endif
  try
    call vimproc#version()
    let s:vimproc_available = 1
  catch
    let s:vimproc_available = 0
  endtry
  return s:vimproc_available
endfunction

function! s:is_supported(options) abort
  if get(a:options, 'background') && (
        \   s:Prelude.is_string(get(a:options, 'input')) ||
        \   get(a:options, 'timeout')
        \)
    return 0
  endif
  return 1
endfunction

function! s:execute(args, options) abort
  let options = extend({
        \ 'input': 0,
        \ 'timeout': 0,
        \ 'background': 0,
        \}, a:options)
  let cmdline = join(map(
        \ copy(a:args),
        \ 'vimproc#shellescape(v:val)',
        \))
  if &verbose > 0
    echomsg printf(
          \ 'vital: System.Process.Vimproc: %s',
          \ cmdline
          \)
  endif
  if options.background
    let output = vimproc#system_bg(cmdline)
    " NOTE:
    " background process via Builtin always return exit_code:0 so mimic
    let status = 0
  else
    let output = vimproc#system(
          \ cmdline,
          \ s:Prelude.is_string(options.input) ? options.input : '',
          \ options.timeout,
          \)
    let status = vimproc#get_last_status()
  endif
    " NOTE:
    " success, output are COMMON information
    " status, errormsg are EXTRA information
  return {
        \ 'success': status == 0,
        \ 'output': output,
        \ 'status': status,
        \ 'errormsg': vimproc#get_last_errmsg(),
        \ 'cmdline': cmdline,
        \}
endfunction

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions
