" See autoload/vital/command.vim .
" This file remains for compatibility

let s:save_cpo = &cpo
set cpo&vim

function! vitalizer#vitalize(...) abort
  return call('vital#command#bundle', a:000)
endfunction

function! vitalizer#complete(...) abort
  return call('vital#command#complete_vitalizer', a:000)
endfunction

function! vitalizer#command(...) abort
  return call('vital#command#run', a:000)
endfunction

let &cpo = s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
