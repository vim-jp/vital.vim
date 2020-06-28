let s:Obj = {}

function! s:_vital_loaded(V) abort
  if exists('s:Lambda')
    call s:Lambda()
  else
    call s:Obj._anonymous_func()
  endif
endfunction

if has('lambda')
  let s:Lambda = {-> s:Obj._anonymous_func()}
endif

function! s:Obj._anonymous_func() dict abort
  call s:_throwFOO()
endfunction

function! s:_throwFOO() abort
  throw 'FOO'
endfunction
