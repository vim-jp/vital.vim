let s:save_cpoptions = &cpoptions
set cpoptions&vim

let s:is_windows = has('win32') " This means any versions of windows https://github.com/vim-jp/vital.vim/wiki/Coding-Rule#how-to-check-if-the-runtime-os-is-windows
let s:is_nvim = has('nvim')

let s:TYPE_DICT = type({})
let s:TYPE_LIST = type([])
let s:TYPE_STRING = type('')

function! s:_vital_loaded(V) abort
  let s:V = a:V
endfunction

function! s:_vital_depends() abort
  return []
endfunction

if s:is_windows
  " iconv() wrapper for safety.
  function! s:iconv(expr, from, to) abort
    if a:from ==# '' || a:to ==# '' || a:from ==? a:to
      return a:expr
    endif
    let result = iconv(a:expr, a:from, a:to)
    return result !=# '' ? result : a:expr
  endfunction
endif

if !s:is_nvim
  " inner callbacks for Vim
  function! s:inner_out_cb(user_out_cb, ch, msg) abort
    let result = a:msg
    if s:is_windows
      let result = s:iconv(a:msg, 'char', &encoding)
    endif

    call a:user_out_cb(result)
  endfunction

  function! s:inner_exit_cb(user_exit_cb, job, exit_code) abort
    call a:user_exit_cb(a:exit_code)
  endfunction

  function! s:inner_err_cb(user_err_cb, ch, msg) abort
    let result = a:msg
    if s:is_windows
      let result = s:iconv(a:msg, 'char', &encoding)
    endif

    call a:user_err_cb(result)
  endfunction
else
  " inner callbacks for Neovim
  function! s:inner_out_cb(user_out_cb, job_id, data, event) abort
    for line in a:data
      if line !=# ''
        call a:user_out_cb(line)
      endif
    endfor
  endfunction

  function! s:inner_exit_cb(user_exit_cb, job_id, exit_code, event) abort
    call a:user_exit_cb(a:exit_code)
  endfunction

  function! s:inner_err_cb(user_err_cb, job_id, data, event) abort
    for line in a:data
      if line !=# ''
        call a:user_err_cb(line)
      endif
    endfor
  endfunction
endif

" execute({command}, {options})
"   {command} = string
"   {options} = {
"     out_cb: function(stdout_msg), " call per line
"     err_cb: function(stderr_msg), " call per line
"     exit_cb: function(exit_code), " call on exit
"   }
function! s:execute(command, options) abort
  if !type(a:options) is s:TYPE_DICT
    throw 'vital: AsyncProcess: invalid argument (value type:' . type(a:options) . ')'
  endif

  " Process a:command argument.
  if type(a:command) is s:TYPE_STRING
    let command = a:command
  elseif type(a:command) is s:TYPE_LIST
    let command = join(a:command, ' ')
  else
    throw 'vital: AsyncProcess: invalid argument (value type:' . type(a:command) . ')'
  endif

  " build args
  let args = []
  if s:is_windows
    let args = args + ['/c']
  else
    let args = args + ['-c']
  endif
  let args = args + [command]

  let job_id = -1
  if s:is_nvim
    let options = {}
    let options['on_stdout'] = function('s:inner_out_cb', [a:options.out_cb])
    let options['on_stderr'] = function('s:inner_err_cb', [a:options.err_cb])
    let options['on_exit'] = function('s:inner_exit_cb', [a:options.exit_cb])

    let job_id = jobstart([&shell] + args, options)

    return {
          \ 'stop': function('jobstop', [job_id]),
          \  }
  else
    let options = {}
    let options['out_cb'] = function('s:inner_out_cb', [a:options.out_cb])
    let options['err_cb'] = function('s:inner_err_cb', [a:options.err_cb])
    let options['exit_cb'] = function('s:inner_exit_cb', [a:options.exit_cb])

    let job = job_start([&shell] + args, options)

    return {
          \ 'stop': function('job_stop', [job]),
          \  }
    }

  endif
endfunction

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions

