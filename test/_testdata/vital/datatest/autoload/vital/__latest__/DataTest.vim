let s:datafile = expand('<sfile>:h') . '/DataTest.txt'

function! s:_vital_loaded(V) abort
  let s:V = a:V
endfunction

function! s:_vital_depends() abort
  return {
    \ 'modules':[],
    \ 'files':  ['DataTest.txt'],
    \}
endfunction

function! s:exists() abort
  return filereadable(s:datafile)
endfunction

function! s:valid() abort
  let data = readfile(s:datafile)
  return (1 ==? len(data)) &&
    \ ('Test Data' ==? data[0])
endfunction
