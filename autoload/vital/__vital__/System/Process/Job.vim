function! s:_vital_loaded(V) abort
  let s:Job = a:V.import('System.Job')
  let s:Prelude = a:V.import('Prelude')
  let s:String = a:V.import('Data.String')
endfunction

function! s:_vital_depends() abort
  return ['System.Job', 'Prelude', 'Data.String']
endfunction

function! s:is_available() abort
  if has('nvim')
    return 1
  elseif exists('*job_start')
    return 1
  endif
  return 0
endfunction

function! s:is_supported(options) abort
  if get(a:options, 'background') && (
        \   s:Prelude.is_string(get(a:options, 'input')) ||
        \   get(a:options, 'timeout')
        \)
    return 0
  endif
  return 1
endfunction

function! s:execute(args, options) abort
  let cmdline = join(a:args)
  if a:options.debug > 0
      echomsg printf(
            \ 'vital: System.Process.Job: %s',
            \ cmdline
            \)
  endif
  let stream = copy(s:stream)
  let stream.timeout = get(a:options, 'timeout')
  let stream._content = []
  let job = s:Job.start(a:args, stream)
  if a:options.background
    return {
          \ 'status': 0,
          \ 'job': job,
          \}
  else
    let status = job.wait(a:options.timeout == 0 ? v:null : a:options.timeout)
    " Follow vimproc's status for backward compatibility
    let status = status == -1 ? 15 : status
    return {
          \ 'job': job,
          \ 'status': status,
          \ 'output': join(stream._content, "\n"),
          \}
  endif
endfunction


" Stream ---------------------------------------------------------------------
let s:stream = {}

function! s:stream.on_stdout(job, msg, event) abort
  let leading = get(self._content, -1, '')
  silent! call remove(self._content, -1)
  call extend(self._content, [leading . get(a:msg, 0, '')] + a:msg[1:])
endfunction

function! s:stream.on_stderr(job, msg, event) abort
  let leading = get(self._content, -1, '')
  silent! call remove(self._content, -1)
  call extend(self._content, [leading . get(a:msg, 0, '')] + a:msg[1:])
endfunction

function! s:stream.on_exit(job, msg, event) abort
  if empty(get(self._content, -1, ''))
    silent! call remove(self._content, -1)
  endif
endfunction
