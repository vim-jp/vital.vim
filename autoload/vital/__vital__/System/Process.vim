let s:save_cpoptions = &cpoptions
set cpoptions&vim

let s:registry = {}
let s:priority = []

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Prelude = a:V.import('Prelude')
  let s:String = a:V.import('Data.String')
  call s:register('System.Process.Vimproc')
  call s:register('System.Process.System')
endfunction

function! s:_vital_depends() abort
  return [
        \ 'Prelude',
        \ 'Data.String',
        \ 'System.Process.System',
        \ 'System.Process.Vimproc',
        \]
endfunction

function! s:_throw(msg) abort
  throw printf('vital: System.Process: %s', a:msg)
endfunction

function! s:register(name) abort
  let client = s:V.import(a:name)
  if client.is_available()
    let s:registry[a:name] = client
    call add(s:priority, a:name)
  endif
endfunction

function! s:_execute(args, options) abort
  for name_or_client in a:options.clients
    let client = s:Prelude.is_string(name_or_client)
          \ ? s:registry[name_or_client]
          \ : name_or_client
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
        \ 'encode_error': 1,
        \ 'split_output': 1,
        \ 'debug': &verbose,
        \}, get(a:000, 0, {}))
  if s:Prelude.is_string(options.input) && !empty(options.encode_input)
    let encoding = s:Prelude.is_string(options.encode_input)
          \ ? options.encode_input
          \ : &encoding
    let options.input = s:String.iconv(options.input, encoding, 'char')
  endif
  let result = s:_execute(a:args, options)
  if s:Prelude.is_string(result.output) && !empty(options.encode_output)
    let encoding = s:Prelude.is_string(options.encode_output)
          \ ? options.encode_output
          \ : &encoding
    let result.output = s:String.iconv(result.output, 'char', encoding)
  endif
  if s:Prelude.is_string(result.error) && !empty(options.encode_error)
    let encoding = s:Prelude.is_string(options.encode_error)
          \ ? options.encode_error
          \ : &encoding
    let result.error = s:String.iconv(result.error, 'char', encoding)
  endif
  if options.split_output
    let result.content = s:String.split_posix_text(result.output)
  endif
  let result.success = result.status == 0
  let result.args = a:args
  let result.options = options
  return result
endfunction

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions
