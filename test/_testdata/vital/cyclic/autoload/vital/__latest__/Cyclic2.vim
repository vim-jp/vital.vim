function! s:_vital_loaded(V) abort
  let s:Cyclic1 = a:V.import('Cyclic1')
endfunction

function! s:_vital_depends() abort
  return ['Cyclic1']
endfunction

function! s:return1() abort
  return s:Cyclic1.return0() + 1
endfunction
