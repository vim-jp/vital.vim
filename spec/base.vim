let &runtimepath = expand('<sfile>:h:h')

let s:results = {}
let s:context_stack = []

function! s:should(cond)
  " FIXME: validate
  let it = s:context_stack[-1][1]
  let context = s:context_stack[-2][1]
  if !has_key(s:results, context)
    let s:results[context] = []
  endif
  call add(s:results[context], s:_should(it, a:cond))
endfunction

function! s:_should(it, cond)
  echo a:cond
  echo eval(a:cond)
  return eval(a:cond) ? '.' : a:it
endfunction

command! -nargs=+ Context
      \ call add(s:context_stack, ['c', <q-args>])
command! -nargs=+ It
      \ call add(s:context_stack, ['i', <q-args>])
command! -nargs=+ Should
      \ call s:should(<q-args>)
command! -nargs=0 End
      \ call remove(s:context_stack, -1) |
      \ redraw!

command! -nargs=+ Fin
      \ call writefile([string(s:results)], <q-args>) |
      \ qa!
