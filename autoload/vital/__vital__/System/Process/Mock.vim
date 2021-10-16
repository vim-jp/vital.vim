let s:save_cpoptions = &cpoptions
set cpoptions&vim

function! s:is_available() abort
  return 1
endfunction

" @vimlint(EVL103, 1, a:options)
function! s:is_supported(options) abort
  return 1
endfunction
" @vimlint(EVL103, 0, a:options)

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
        \}
endfunction

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions
