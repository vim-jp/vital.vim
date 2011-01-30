let s:vital = {'version': '__latest__'}

function! s:vital.system(x)
  echo "this is the latest version(" . a:x . ") implementation of system()!"
  return 1
endfunction

function! vital#__latest__#new()
  return s:vital
endfunction
