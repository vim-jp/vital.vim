let s:save_cpo = &cpo
set cpo&vim

let s:_processes_i = -1
let s:_processes = {}

function! s:_vital_loaded(V)
  let s:V = a:V
endfunction

function! s:is_available()
  return s:V.has_vimproc()
endfunction

function! s:touch(name, cmd)
  if has_key(s:_processes, a:name)
    return 'existing'
  else
    let p = vimproc#popen3(a:cmd)
    let s:_processes[a:name] = p
    return 'new'
  endif
endfunction

function! s:new(cmd)
  let p = vimproc#popen3(a:cmd)
  let s:_processes_i += 1
  let s:_processes[s:_processes_i] = p
  return s:_processes_i
endfunction

function! s:stop(i)
  let p = s:_processes[a:i]
  call p.kill(9)
  unlet s:_processes[s:_processes_i]
endfunction

function! s:read(i)
  return s:read_wait(a:i, 0.1)
endfunction

function! s:read_wait(i, wait)
  if !has_key(s:_processes, a:i)
    throw printf("ProcessManager doesn't know about %s", a:i)
  endif

  let p = s:_processes[a:i]
  let out_memo = ''
  let err_memo = ''
  let lastchanged = reltime()
  while 1
    let [x, y] = [p.stdout.read(), p.stderr.read()]
    if x ==# '' && y ==# ''
      if str2float(reltimestr(reltime(lastchanged))) > a:wait
        return [out_memo, err_memo]
      endif
    else
      let lastchanged = reltime()
      let out_memo .= x
      let err_memo .= y
    endif
  endwhile
endfunction

function! s:write(i, str)
  if !has_key(s:_processes, a:i)
    throw printf("ProcessManager doesn't know about %s", a:i)
  endif

  let p = s:_processes[a:i]
  call p.stdin.write(a:str)
endfunction

function! s:writeln(i, str)
  return s:write(a:i, a:str . "\n")
endfunction

" let i = s:new('clojure-1.5')
" echo s:read_wait(i, 2.0)
" call s:writeln(i, '(j 1)(+ 2 3)')
" echo s:read(i)
" echo s:stop(i)

let &cpo = s:save_cpo
unlet s:save_cpo
" vim:set et ts=2 sts=2 sw=2 tw=0:
