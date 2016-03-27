function! s:_vital_loaded(V) abort
  let s:Cyclic2 = a:V.import('Cyclic2')
endfunction

function! s:_vital_depends() abort
  return ['Cyclic2']
endfunction

function! s:return0() abort
  return 0
endfunction

function! s:return1() abort
  return s:Cyclic2.return1()
endfunction
