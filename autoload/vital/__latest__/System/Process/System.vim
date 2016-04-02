let s:save_cpoptions = &cpoptions
set cpoptions&vim

function! s:_vital_loaded(V) abort
  let s:Prelude = a:V.import('Prelude')
  let s:String = a:V.import('Data.String')
  let s:Guard = a:V.import('Vim.Guard')
endfunction

function! s:_vital_depends() abort
  return [
        \ 'Prelude',
        \ 'Data.String',
        \ 'Vim.Guard',
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
    if a:options.background && !s:Prelude.is_windows()
      let cmdline = cmdline . ' &'
    endif
    if a:options.debug > 0
      echomsg printf(
            \ 'vital: System.Process.System: %s',
            \ cmdline
            \)
    endif
    if v:version < 704 || (v:version == 704 && !has('patch122'))
      " {cmdline} of system() before Vim 7.4.122 is not converted so convert
      " it manually from &encoding to 'char'
      let cmdline = s:String.iconv(cmdline, &encoding, 'char')
    endif
    let args = [cmdline] + (s:Prelude.is_string(a:options.input) ? [a:options.input] : [])
    let output = call('system', args)
    if s:Prelude.is_windows()
      " A builtin system() add a trailing space in Windows.
      " It is probably an issue of pipe in Windows so remove it.
      let output = substitute(output, '\s\n$', '\n', '')
    endif
    " NOTE:
    " Vim 7.4 always return exit_status:0 for background process so mimic
    let status = a:options.background ? 0 : v:shell_error
    " NOTE:
    " status, output are COMMON information
    " cmdline is an EXTRA information
    return {
          \ 'status': status,
          \ 'output': output,
          \ 'cmdline': cmdline,
          \}
  finally
    call guard.restore()
  endtry
endfunction

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions
