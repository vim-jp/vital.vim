let s:save_cpo = &cpo
set cpo&vim

function! s:create(opt) abort
    echom 'create popup'
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttab et ai textwidth=0 fdm=marker
