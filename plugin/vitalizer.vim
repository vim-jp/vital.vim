" vitalizer by vim script.

if exists('g:loaded_vitalizer')
  finish
elseif v:version < 800
  echoerr "vital.vim does not work this version of Vim"
endif
let g:loaded_vitalizer = 1

let s:save_cpo = &cpo
set cpo&vim

" :Vitalize {options} {target-dir} [module ...]
command! -nargs=* -complete=customlist,vitalizer#complete Vitalize
\        call vitalizer#command([<f-args>])

let &cpo = s:save_cpo
unlet s:save_cpo
