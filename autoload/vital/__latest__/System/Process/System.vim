let s:save_cpoptions = &cpoptions
set cpoptions&vim

function! s:_vital_loaded(V) abort
  let s:Prelude = a:V.import('Prelude')
  let s:Guard = a:V.import('Vim.Guard')
  let s:Process = a:V.import('System.Process')
endfunction

function! s:_vital_depends() abort
  return [
        \ 'Prelude',
        \ 'Vim.Guard',
        \ 'System.Process',
        \]
endfunction

function! s:is_available() abort
  return 1
endfunction

function! s:is_supported(options) abort
  if get(a:options, 'timeout')
    return 0
  elseif get(a:options, 'background') && s:Prelude.is_windows()
    return 0
  endif
  return 1
endfunction

function! s:shellescape(string) abort
  if s:Prelude.is_windows()
    " NOTE:
    " In windows, a string which does not contain space SHOULD NOT be escaped
    return a:string =~# '\s' ? shellescape(a:string) : a:string
  else
    return shellescape(a:string)
  endif
endfunction

function! s:execute(args, options) abort
  let options = extend({
        \ 'input': 0,
        \}, a:options)
  " NOTE:
  " execute() is a command for executing program WITHOUT using shell.
  " so mimic that behaviour with shell
  let guard = call(s:Guard.store, filter([
        \ '&shell',
        \ '&shellcmdflag',
        \ '&shellquote',
        \ '&shellredir',
        \ '&shelltemp',
        \ (exists('+shelltype') ? '&shelltype' : ''),
        \ (exists('+shellxescape') ? '&shellxescape' : ''),
        \ (exists('+shellxquote') ? '&shellxquote' : ''),
        \ (exists('+shellslash') ? '&shellslash' : ''),
        \], '!empty(v:val)'), s:Guard)
  try
    " Reset shell related options
    if s:Prelude.is_windows()
      set shell&
      if exists('+shellslash')
        set shellslash&
      endif
    else
      set shell=sh
    endif
    set shellcmdflag& shellquote& shellredir& shelltemp&
    if exists('+shelltype')
      set shelltype&
    endif
    if exists('+shellxescape')
      set shellxescape&
    endif
    if exists('+shellxquote')
      set shellxquote&
    endif
    let cmdline = join(map(
          \ copy(a:args),
          \ 's:shellescape(v:val)',
          \))
    if options.background && !s:Prelude.is_windows()
      let cmdline = cmdline . ' &'
    endif
    if &verbose > 0
      echomsg printf(
            \ 'vital: System.Process.System: %s',
            \ cmdline
            \)
    endif
    if v:version < 704 || (v:version == 704 && !has('patch122'))
      " {cmdline} of system() before Vim 7.4.122 is not converted so convert
      " it manually from &encoding to 'char'
      let cmdline = s:Process.iconv(cmdline, &encoding, 'char')
    endif
    let args = [cmdline] + (s:Prelude.is_string(options.input) ? [options.input] : [])
    let output = call('system', args)
    if s:Prelude.is_windows()
      " A builtin system() add a trailing space in Windows.
      " It is probably an issue of pipe in Windows so remove it.
      let output = substitute(output, '\s\n$', '\n', '')
    endif
    " NOTE:
    " Vim 7.4 always return exit_status:0 for background process so mimic
    let status = options.background ? 0 : v:shell_error
    " NOTE:
    " success, output are COMMON information
    " status, cmdline are EXTRA information
    return {
          \ 'success': status == 0,
          \ 'output': output,
          \ 'status': status,
          \ 'cmdline': cmdline,
          \}
  finally
    call guard.restore()
  endtry
endfunction

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions
