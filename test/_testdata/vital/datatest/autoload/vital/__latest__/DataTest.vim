function! s:_vital_loaded(V) abort
  let s:V = a:V
endfunction

function! s:_vital_depends() abort
  return {'modules':[], 'files':['DataTest.txt']}
endfunction

function! s:dummy() abort
  return 0
endfunction

