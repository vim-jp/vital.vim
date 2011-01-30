let s:vital = {'version': 'v0_0_1'}

function! s:vital.system(x)
  echo "this is the version 0.0.1 implementation of system()!"
  return 1
endfunction

function! vital#v0_0_1#new()
  return s:vital
endfunction
