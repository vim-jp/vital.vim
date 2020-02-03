let s:tasks = []
let s:timer = v:null

function! s:call(fn, ...) abort
  call add(s:tasks, [a:fn, a:000])
  call s:_emit()
endfunction

function! s:_emit() abort
  if v:dying || s:timer isnot# v:null || empty(s:tasks)
    return
  endif
  let s:timer = timer_start(0, funcref('s:_callback'))
endfunction

function! s:_callback(timer) abort
  let s:timer = v:null
  if v:dying || empty(s:tasks)
    return
  endif
  try
    call call('call', remove(s:tasks, 0))
  catch
    let ms = split(v:exception . "\n" . v:throwpoint, '\n')
    echohl ErrorMsg
    for m in ms
      echomsg m
    endfor
    echohl None
  endtry
  call s:_emit()
endfunction
