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
          \}
    if has_key(job, 'on_stdout')
      let job_options.out_cb = function('s:_job_callback', ['stdout', job])
    endif
    if has_key(job, 'on_stderr')
      let job_options.err_cb = function('s:_job_callback', ['stderr', job])
    endif
    if has_key(job, 'on_exit')
      let job_options.exit_cb = function('s:_job_callback', ['exit', job])
    endif
    let job.__job = job_start(a:args, job_options)
    let job.__channel = job_getchannel(job.__job)
    let job.args = a:args
    return job
  endfunction

  function! s:_job_callback(event, options, channel, ...) abort
    let raw = get(a:000, 0, '')
    let msg = type(raw) == v:t_string ? split(raw, '\n', 1) : raw
    call call(
          \ a:options['on_' . a:event],
          \ [a:channel, msg, a:event],
          \ a:options
          \)
  endfunction

  function! s:_ch_read_and_call_callbacks(job) abort
    let status = ch_status(a:job.__channel)
    if status ==# 'open' || status ==# 'buffered'
      let stdout = ch_read(a:job.__channel)
      let stderr = ch_read(a:job.__channel, {'part': 'err'})
      if has_key(a:job, 'on_stdout') && !empty(stdout)
        call s:_job_callback('stdout', a:job, a:job.__job, stdout)
      endif
      if has_key(a:job, 'on_stderr') && !empty(stderr)
        call s:_job_callback('stderr', a:job, a:job.__job, stderr)
      endif
    endif
  endfunction

  " Instance -------------------------------------------------------------------
  let s:job = {}

  " NOTE:
  " On Unix a non-existing command results in "dead" instead
  " So returns "dead" instead of "fail" even in non Unix.
  function! s:job.status() abort
    let status = job_status(self.__job)
    return status ==# 'fail' ? 'dead' : status
  endfunction

  function! s:job.send(data) abort
    return ch_sendraw(self.__channel, a:data)
  endfunction

  function! s:job.stop() abort
    return job_stop(self.__job)
  endfunction

  function! s:job.wait(...) abort
    let timeout = get(a:000, 0, v:null)
    let timeout = timeout is# v:null ? v:null : timeout / 1000.0
    let start_time = reltime()
    try
      while timeout is# v:null || timeout > reltimefloat(reltime(start_time))
        let status = self.status()
        if status ==# 'fail'
          return -3
        elseif status ==# 'dead'
          call s:_ch_read_and_call_callbacks(self)
          let info = job_info(self.__job)
          return info.exitval
        endif
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
