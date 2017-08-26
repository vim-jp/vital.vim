let s:t_list = type([])


" NOTE:
" Attributes of {options} dictionary start from double underscore (__) are
" used internally so no custom attributes shall start from that.
if has('nvim')
  function! s:start(args, ...) abort
    call s:_validate_args(a:args)
    " Build options for jobstart
    let options = get(a:000, 0, {})
    let job = extend(copy(options), s:job)
    if has_key(options, 'on_exit')
      let job.__on_exit = options.on_exit
    endif
    " Start job and return a job instance
    let job.__job = jobstart(a:args, job)
    let job.__status = job.__job > 0 ? 'run' : 'dead'
    let job.args = a:args
    return job
  endfunction


  " Instance -------------------------------------------------------------------
  let s:job = {}

  function! s:job.id() abort
    return self.__job
  endfunction

  function! s:job.status() abort
    return self.__status
  endfunction

  function! s:job.send(data) abort
    return jobsend(self.__job, a:data)
  endfunction

  function! s:job.stop() abort
    try
      call jobstop(self.__job)
      let self.__status = 'dead'
    catch /^Vim\%((\a\+)\)\=:E900/
      " NOTE:
      " Vim does not raise exception even the job has already closed so fail
      " silently for 'E900: Invalid job id' exception
    endtry
  endfunction

  function! s:job.wait(...) abort
    let timeout = get(a:000, 0, v:null)
    if timeout is# v:null
      return jobwait([self.__job])[0]
    else
      return jobwait([self.__job], timeout)[0]
    endif
  endfunction

  function! s:job.on_exit(job, msg, event) abort
    " Update job status
    let self.__status = 'dead'
    " Call user specified callback if exists
    if has_key(self, '__on_exit')
      call call(self.__on_exit, [a:job, a:msg, a:event], self)
    endif
  endfunction
else
  function! s:start(args, ...) abort
    call s:_validate_args(a:args)
    let job = extend(copy(s:job), get(a:000, 0, {}))
    let job_options = {
          \ 'mode': 'raw',
          \ 'timeout': 10000,
          \ 'out_cb': function('s:_on_msg_cb', ['stdout', job]),
          \ 'err_cb': function('s:_on_msg_cb', ['stderr', job]),
          \ 'exit_cb': function('s:_on_exit_cb', [job]),
          \}
    let job.__job = job_start(a:args, job_options)
    let job.__channel = job_getchannel(job.__job)
    let job.args = a:args
    return job
  endfunction

  function! s:_on_msg_cb(name, job, channel, msg) abort
    let cb_name = 'on_' . a:name
    if has_key(a:job, cb_name)
      call call(a:job[cb_name], [a:channel, split(a:msg, '\r\?\n', 1), a:name])
    endif
  endfunction

  function! s:_on_exit_cb(job, job8, exitval) abort
    " There might be data remain so read channel and call corresponding
    " callbacks to mimic 'on_exit' of Neovim
    call s:_read_channel_and_call_callback(a:job, 'stdout', {})
    call s:_read_channel_and_call_callback(a:job, 'stderr', {'part': 'err'})
    if has_key(a:job, 'on_exit')
      call call(a:job.on_exit, [a:job8, a:exitval, 'exit'])
    endif
  endfunction

  function! s:_read_channel_and_call_callback(job, name, options) abort
    let status = ch_status(a:job.__channel, a:options)
    while status ==# 'open' || status ==# 'buffered'
      if status ==# 'buffered'
        let msg = ch_read(a:job.__channel, a:options)
        call s:_on_msg_cb(a:name, a:job, a:job.__channel, msg)
      endif
      " Without sleep, Vim would hung
      sleep 1m
      let status = ch_status(a:job.__channel, a:options)
    endwhile
  endfunction

  " Instance -------------------------------------------------------------------
  let s:job = {}

  function! s:job.id() abort
    return str2nr(matchstr(string(self.__job), '^process \zs\d\+\ze'))
  endfunction

  " NOTE:
  " On Unix a non-existing command results in "dead" instead
  " So returns "dead" instead of "fail" even in non Unix.
  function! s:job.status() abort
    let status = job_status(self.__job)
    return status ==# 'fail' ? 'dead' : status
  endfunction

  " NOTE:
  " A Null character (\0) is used as a terminator of a string in Vim.
  " Neovim can send \0 by using \n splitted list but in Vim.
  " So replace all \n in \n splitted list to ''
  function! s:job.send(data) abort
    let data = type(a:data) == s:t_list
          \ ? join(map(a:data, 'substitute(v:val, "\n", '''', ''g'')'), "\n")
          \ : a:data
    return ch_sendraw(self.__channel, data)
  endfunction

  function! s:job.stop() abort
    return job_stop(self.__job)
  endfunction

  function! s:job.wait(...) abort
    if !has('patch-8.0.0027')
      throw 'vital: System.Job: Vim 8.0.0026 and earlier is not supported.'
    endif
    let timeout = get(a:000, 0, v:null)
    let timeout = timeout is# v:null ? v:null : timeout / 1000.0
    let start_time = reltime()
    try
      while timeout is# v:null || timeout > reltimefloat(reltime(start_time))
        let status = self.status()
        if status ==# 'fail'
          return -3
        elseif status ==# 'dead'
          let info = job_info(self.__job)
          return info.exitval
        endif
        " Without sleep, Vim hung.
        sleep 1m
      endwhile
    catch /^Vim:Interrupt$/
      call self.stop()
      return 1
    endtry
    return -1
  endfunction
endif


" Note:
" A string {args} is not permitted while Vim/Neovim treat that a bit
" differently and makes thing complicated.
" Note:
" Vim does not raise E902 on Unix system even the prog is not found so use a
" custom exception instead to make the method compatible.
function! s:_validate_args(args) abort
  if type(a:args) != s:t_list
    throw 'vital: System.Job: Argument requires to be a List instance.'
  elseif len(a:args) == 0
    throw 'vital: System.Job: Argument vector must have at least one item.'
  endif
  let prog = a:args[0]
  if !executable(prog)
    throw printf('vital: System.Job: "%s" is not an executable', prog)
  endif
endfunction
