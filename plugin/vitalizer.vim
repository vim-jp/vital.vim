" vitalizer by vim script.

if exists('g:loaded_vitalizer')
  finish
endif
let g:loaded_vitalizer = 1

let s:save_cpo = &cpo
set cpo&vim

" :Vitalize {options} {target-dir} [module ...]
command! -nargs=* -complete=customlist,vitalizer#complete Vitalize
\        call vitalizer#command([<f-args>])

let &cpo = s:save_cpo
unlet s:save_cpo
