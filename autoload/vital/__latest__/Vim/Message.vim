
let s:save_cpo = &cpo
set cpo&vim


function! s:echomsg(hl, msg) abort
  execute 'echohl' a:hl
  try
    echomsg a:msg
  finally
    echohl None
  endtry
endfunction

function! s:warn(msg)
  call s:echomsg('WarningMsg', a:msg)
endfunction

function! s:error(msg)
  call s:echomsg('ErrorMsg', a:msg)
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
