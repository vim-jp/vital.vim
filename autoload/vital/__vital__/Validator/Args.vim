" Arguments validation library

let s:save_cpo = &cpo
set cpo&vim

let s:NONE = []
lockvar! s:NONE

let s:TYPE = {}
let s:TYPE.NUMBER = 0
let s:TYPE.STRING = 1
let s:TYPE.FUNC = 2
let s:TYPE.LIST = 3
let s:TYPE.DICT = 4
let s:TYPE.FLOAT = 5
let s:TYPE.BOOL = 6
let s:TYPE.NONE = 7
let s:TYPE.JOB = 8
let s:TYPE.CHANNEL = 9
let s:TYPE.ANY = range(s:TYPE.NUMBER, s:TYPE.CHANNEL)
let s:TYPE.OPTARG = []
lockvar! s:TYPE

let s:TYPES = ['Number', 'String', 'Funcref', 'List', 'Dictionary', 'Float']
if v:version >=# 800
  let s:TYPES += ['Bool', 'None', 'Job', 'Channel']
endif
lockvar! s:TYPES

function! s:_vital_created(module) abort
  let a:module.TYPE = s:TYPE
endfunction


function! s:of(prefix) abort
  if type(a:prefix) isnot s:TYPE.STRING
    throw 'Validator.Args: of(): expected String argument ' .
    \     'but got ' . s:TYPES[type(a:prefix)]
  endif
  let validator = {'_prefix': a:prefix, '_asserts': {}}
  function! validator.type(...) abort
    if len(filter(copy(a:000), 'v:val is s:TYPE.OPTARG')) >= 2
      throw 'Validator.Args: multiple OPTARG were given'
    endif
    let self._types = a:000
    return self
  endfunction
  function! validator.assert(no, funclist, ...) abort
    let self._asserts[a:no - 1] = {
    \ 'funclist': type(a:funclist) is s:TYPE.LIST ? a:funclist : [a:funclist],
    \ 'msg': get(a:000, 0, 'the ' . a:no . 'th argument''s assertion failed')
    \}
    return self
  endfunction
  function! validator.validate(args) abort
    if type(a:args) isnot s:TYPE.LIST
      throw 'Validator.Args: Validator.validate(): expected List argument ' .
      \     'but got ' . s:TYPES[type(a:args)]
    endif
    if has_key(self, '_types')
      call s:_validate_arg_types(a:args, self._types, self._prefix)
    endif
    if !empty(self._asserts)
      call s:_validate_arg_assert(a:args, self._asserts, self._prefix)
    endif
  endfunction
  return validator
endfunction

function! s:_validate_arg_types(args, types, prefix) abort
  let optarg = 0
  let typelen = len(a:types)
  let argslen = len(a:args)
  let i = 0
  while i < argslen
    if i + optarg >= typelen
      if optarg && a:types[-1] is s:TYPE.OPTARG
        break
      else
        throw a:prefix . ': too many arguments'
      endif
    endif
    if a:types[i + optarg] is s:TYPE.OPTARG
      let optarg += 1
      continue
    endif
    call s:_validate_type(
    \ a:args[i], a:types[i + optarg], a:prefix
    \)
    let i += 1
  endwhile
  if !optarg && i < typelen && a:types[i] isnot s:TYPE.OPTARG
    throw a:prefix . ': too few arguments'
  endif
endfunction

function! s:_validate_type(value, expected_type, prefix, ...) abort
  if type(a:expected_type) is s:TYPE.LIST
    let matched = filter(copy(a:expected_type),
    \     's:_validate_type(a:value, v:val, a:prefix, s:NONE) isnot s:NONE')
    if empty(matched)
      if a:0
        return a:1
      endif
      let expected = join(map(copy(a:expected_type), 's:TYPES[v:val]'), ' or ')
      throw a:prefix . ': invalid type arguments were given ' .
      \     '(expected: ' . expected .
      \     ', got: ' . s:TYPES[type(a:value)] . ')'
    endif
    return
  endif
  if type(a:value) isnot a:expected_type
    if a:0
      return a:1
    endif
    throw a:prefix . ': invalid type arguments were given ' .
    \     '(expected: ' . s:TYPES[a:expected_type] .
    \     ', got: ' . s:TYPES[type(a:value)] . ')'
  endif
  return a:value
endfunction

function! s:_validate_arg_assert(args, asserts, prefix) abort
  for i in range(len(a:args))
    if has_key(a:asserts, i)
      call s:_validate_assert(
      \       a:args[i], a:asserts[i].funclist, a:asserts[i].msg, a:prefix)
    endif
  endfor
endfunction

function! s:_validate_assert(value, funclist, msg, prefix) abort
  let matched = filter(copy(a:funclist), 's:_call1(v:val, a:value)')
  if empty(matched)
    throw a:prefix . ': ' . a:msg
  endif
endfunction

function! s:_call1(f, arg) abort
  if type(a:f) is s:TYPE.FUNC
    return call(a:f, [a:arg])
  else
    return map([a:arg], a:f)[0]
  endif
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
