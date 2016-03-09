let s:save_cpoptions = &cpoptions
set cpoptions&vim

let s:registry = {}
let s:priority = []

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Prelude = a:V.import('Prelude')
  call s:register('System.Process.Vimproc', 'vimproc')
  call s:register('System.Process.Builtin', 'builtin')
endfunction

function! s:_vital_depends() abort
  return [
        \ 'Prelude',
        \ 'System.Process.Vimproc',
        \ 'System.Process.Builtin',
        \]
endfunction

function! s:_throw(msg) abort
  throw printf('vital: System.Process: %s', a:msg)
endfunction

function! s:register(name, ...) abort
  let alias = get(a:000, 0, a:name)
  let client = s:V.import(a:name)
  if client.is_available()
    let s:registry[alias] = client
    call add(s:priority, alias)
  endif
endfunction

function! s:iconv(expr, from, to) abort
  if a:from ==# '' || a:to ==# '' || a:from ==? a:to
    return a:expr
  endif
  let result = iconv(a:expr, a:from, a:to)
  return empty(result) ? a:expr : result
endfunction

" NOTE:
" A definition of a TEXT file is "A file that contains characters organized
" into one or more lines."
" A definition of a LINE is "A sequence of zero ore more non- <newline>s
" plus a terminating <newline>"
" That's why {stdin} always end with <newline> ideally. However, there are
" some program which does not follow the POSIX rule and a Vim's way to join
" List into TEXT; join({text}, "\n"); does not add <newline> to the end of
" the last line.
" That's why add a trailing <newline> if it does not exist.
" REF:
" http://pubs.opengroup.org/onlinepubs/000095399/basedefs/xbd_chap03.html#tag_03_392
" http://pubs.opengroup.org/onlinepubs/000095399/basedefs/xbd_chap03.html#tag_03_205
" :help split()
" NOTE:
" it does nothing if the text is a correct POSIX text
function! s:repair_posix_text(text, ...) abort
  let newline = get(a:000, 0, "\n")
  return a:text =~# '\r\?\n$' ? a:text : a:text . newline
endfunction

" NOTE:
" A definition of a TEXT file is "A file that contains characters organized
" into one or more lines."
" A definition of a LINE is "A sequence of zero ore more non- <newline>s
" plus a terminating <newline>"
" REF:
" http://pubs.opengroup.org/onlinepubs/000095399/basedefs/xbd_chap03.html#tag_03_392
" http://pubs.opengroup.org/onlinepubs/000095399/basedefs/xbd_chap03.html#tag_03_205
function! s:join_posix_lines(lines, ...) abort
  let newline = get(a:000, 0, "\n")
  return join(a:lines, newline) . newline
endfunction

" NOTE:
" A definition of a TEXT file is "A file that contains characters organized
" into one or more lines."
" A definition of a LINE is "A sequence of zero ore more non- <newline>s
" plus a terminating <newline>"
" TEXT into List; split({text}, '\r\?\n', 1); add an extra empty line at the
" end of List because the end of TEXT ends with <newline> and keepempty=1 is
" specified. (btw. keepempty=0 cannot be used because it will remove
" emptylines in head and tail).
" That's why remove a trailing <newline> before proceeding to 'split'
" REF:
" http://pubs.opengroup.org/onlinepubs/000095399/basedefs/xbd_chap03.html#tag_03_392
" http://pubs.opengroup.org/onlinepubs/000095399/basedefs/xbd_chap03.html#tag_03_205
function! s:split_posix_text(text, ...) abort
  let newline = get(a:000, 0, '\r\?\n')
  let text = substitute(a:text, newline . '$', '', '')
  return split(text, newline, 1)
endfunction

function! s:_execute(args, options) abort
  for alias in a:options.clients
    let client = s:registry[alias]
    if !client.is_supported(a:options)
      continue
    endif
    return client.execute(a:args, a:options)
  endfor
  call s:_throw(printf(
        \ 'None of client support options : %s',
        \ string(a:options),
        \))
endfunction

" execute({args}[, {options}])
function! s:execute(args, ...) abort
  let options = extend({
        \ 'clients': s:priority,
        \ 'input': 0,
        \ 'timeout': 0,
        \ 'background': 0,
        \ 'encode_input': 1,
        \ 'encode_output': 1,
        \ 'embed_content': 1,
        \}, get(a:000, 0, {}))
  if s:Prelude.is_string(options.input) && options.encode_input
    let encoding = s:Prelude.is_string(options.encode_input)
          \ ? options.encode_input
          \ : &encoding
    let options.input = s:iconv(options.input, encoding, 'char')
  endif
  let result = s:_execute(a:args, options)
  if s:Prelude.is_string(result.output) && options.encode_output
    let encoding = s:Prelude.is_string(options.encode_output)
          \ ? options.encode_output
          \ : &encoding
    let result.output = s:iconv(result.output, 'char', encoding)
  endif
  if options.embed_content
    let result.content = s:split_posix_text(result.output)
  endif
  let result.args = a:args
  let result.options = options
  return result
endfunction

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions
