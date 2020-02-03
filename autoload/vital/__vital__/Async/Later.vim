let s:tasks = []
let s:workers = []
let s:max_workers = 50

function! s:call(fn, ...) abort
  call add(s:tasks, [a:fn, a:000])
  if empty(s:workers)
    call add(s:workers, timer_start(0, s:Worker, { 'repeat': -1 }))
  endif
endfunction

function! s:get_max_workers(n) abort
  return s:max_workers
endfunction

function! s:set_max_workers(n) abort
  let s:max_workers = a:n
endfunction

function! s:_worker(...) abort
  if v:dying
    return
  endif
  let n_workers = len(s:workers)
  if empty(s:tasks)
    if n_workers
      call timer_stop(remove(s:workers, 0))
    endif
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
  if n_workers < s:max_workers
    call add(s:workers, timer_start(0, s:Worker, { 'repeat': -1 }))
  endif
endfunction

let s:Worker = funcref('s:_worker')
