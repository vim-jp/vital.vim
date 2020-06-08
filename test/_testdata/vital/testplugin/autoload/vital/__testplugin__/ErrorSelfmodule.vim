function! s:_vital_loaded(V) abort
  call s:Obj._anonymous_func()
endfunction

let s:Obj = {}
function! s:Obj._anonymous_func() dict abort
  call s:_throwFOO()
endfunction

function! s:_throwFOO() abort
  throw 'FOO'
endfunction
