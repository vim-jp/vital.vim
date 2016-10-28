let s:save_cpoptions = &cpoptions
set cpoptions&vim

function! s:is_available() abort
  return 1
endfunction

function! s:is_supported(options) abort
  return 1
endfunction

function! s:execute(args, options) abort
  if a:options.debug > 0
    echomsg printf(
          \ 'vital: System.Process.Mock: %s',
          \ join(a:args)
          \)
  endif
  return {
        \ 'status': 0,
        \ 'output': 'Output of System.Process.Mock',
        \ 'error': '',
        \}
endfunction

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions
