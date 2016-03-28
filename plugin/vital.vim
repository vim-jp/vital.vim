if exists('g:loaded_vital')
  finish
endif
let g:loaded_vital = 1
let s:save_cpo = &cpo
set cpo&vim

" autoload/vital.vim is distributed to plugins which use vital.vim, so this
" autoload function is defined in plugin/vital.vim instead to avoid
" conflictions. Note that defining autoload function under plugin/ directory
" is not recommended nor specified in the doc (:h autoload). Please be
" careful.
function! vital#import(...) abort
  return call('vital#_latest__#import', a:000)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
