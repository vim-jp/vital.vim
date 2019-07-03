" vital commands.

if exists('g:loaded_vital')
  finish
endif
let g:loaded_vital = 1

let s:save_cpo = &cpo
set cpo&vim

" :Vitalize {options} {target-dir} [module ...]
command! -nargs=* -complete=customlist,vital#command#complete_bundle Vitalize
\        Vital bundle <args>
" :Vital {subcommand} ...
command! -nargs=* -complete=customlist,vital#command#complete Vital
\        call vital#command#run([<f-args>])

let &cpo = s:save_cpo
unlet s:save_cpo
