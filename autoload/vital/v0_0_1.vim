let s:util = {'version': 'v0_0_1'}

function! s:util.system(x)
  echo "this is the version 0.0.1 implementation of system()!"
  return 1
endfunction

function! util#v0_0_1#new()
  return s:util
endfunction
