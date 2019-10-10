" Arguments validation library

let s:save_cpo = &cpo
set cpo&vim

let s:NONE = []
lockvar! s:NONE

function! s:_vital_loaded(V) abort
  let s:T = a:V.import('Vim.Type')

  let s:t_end = -1
  for t in has('nvim') ? [
  \ exists('v:null') ? type(v:null) : -1,
  \ exists('v:true') ? type(v:true) : -1,
  \ type(0.0),
  \ type({}),
  \ type([]),
  \ type(function('function')),
  \ type(''),
  \ type(0),
  \] : [
  \ get(v:, 't_blob', -1),
  \ get(v:, 't_channel', -1),
  \ get(v:, 't_job', -1),
  \ get(v:, 't_none', -1),
  \ get(v:, 't_bool', -1),
  \ get(v:, 't_float', -1),
  \ get(v:, 't_dict', -1),
  \ get(v:, 't_list', -1),
  \ get(v:, 't_func', -1),
  \ get(v:, 't_string', -1),
  \ get(v:, 't_number', -1),
  \]
    if t >= 0
      let s:t_end = t
      break
    endif
  endfor
endfunction

function! s:_vital_depends() abort
  return ['Vim.Type']
endfunction

function! s:of(prefix, ...) abort
  if type(a:prefix) isnot# v:t_string
    throw 'vital: Validator.Args: of(): expected ' . s:_type_name(v:t_string) .
    \     ' argument but got ' . s:_type_name(type(a:prefix))
  endif
  let validator = {
  \ '_prefix': a:prefix,
  \ '_asserts': {},
  \ '_enable': !!get(a:000, 0, 1),
  \}
  function! validator.type(...) abort
    call s:_check_type_args(a:000)
    for index in keys(self._asserts)
      call s:_check_out_of_range(index + 1, a:000)
    endfor
    let self._types = a:000
    return self
  endfunction
  function! validator.assert(no, funclist, ...) abort
    call s:_check_assert_args([a:no, a:funclist] + a:000)
    if has_key(self, '_types')
      call s:_check_out_of_range(a:no, self._types)
    endif
    let self._asserts[a:no - 1] = {
    \ 'funclist': type(a:funclist) is# v:t_list ? a:funclist : [a:funclist],
    \ 'msg': get(a:000, 0, 'the ' . a:no . 'th argument''s assertion was failed')
    \}
    return self
  endfunction
  function! validator.validate(args) abort
    if !self._enable
      return a:args
    endif
    if type(a:args) isnot# v:t_list
      throw 'vital: Validator.Args: Validator.validate(): expected ' . s:_type_name(v:t_list) .
      \     ' argument but got ' . s:_type_name(type(a:args))
    endif
    if has_key(self, '_types')
      call s:_validate_arg_types(a:args, self._types, self._prefix)
    endif
    if !empty(self._asserts)
      call s:_validate_arg_assert(a:args, self._asserts, self._prefix)
    endif
    return a:args
  endfunction
  return validator
endfunction

function! s:_check_type_args(args) abort
  let optarg = 0
  for i in range(len(a:args))
    if a:args[i] is# 'option'
      let optarg += 1
      if optarg > 1
        throw 'vital: Validator.Args: Validator.type(): multiple optional arguments were given'
      endif
    endif
    if !s:_is_valid_type_arg(a:args[i])
      throw 'vital: Validator.Args: Validator.type(): expected type or union types ' .
      \     'but got ' . s:_type_name(type(a:args[i]))
    endif
  endfor
endfunction

function! s:_is_valid_type_arg(arg) abort
  let n = type(a:arg)
  if n is# v:t_number && (v:t_number <=# a:arg && a:arg <=# s:t_end)
    return 1
  endif
  if n is# v:t_string && (a:arg is# 'any' || a:arg is# 'option')
    return 1
  endif
  if n is# v:t_list && empty(filter(copy(a:arg), '!s:_is_valid_type_arg(v:val)'))
    return 1
  endif
  return 0
endfunction

function! s:_type_name(type) abort
  if !s:_is_valid_type_arg(a:type)
    throw 'vital: Validator.Args: invalid type value: ' . string(a:type)
  endif
  let n = type(a:type)
  if n is# v:t_number
    return s:T.type_names[a:type]
  elseif n is# v:t_string
    return a:type
  else
    return join(map(copy(a:type), 's:_type_name(v:val)'), ' or ')
  endif
endfunction

function! s:_check_assert_args(args) abort
  let no = a:args[0]
  if no <= 0
    throw 'vital: Validator.Args: Validator.assert(): ' .
    \     'the first argument number was not positive'
  endif
endfunction

function! s:_check_out_of_range(no, types) abort
  let idx = index(a:types, 'option')
  if a:no > len(a:types) - (idx >= 0 && idx !=# len(a:types) - 1 ? 1 : 0)
    if idx >= 0
      let arity = idx . '-' . (len(a:types) - idx)
    else
      let arity = len(a:types)
    endif
    throw 'vital: Validator.Args: Validator.assert(): ' .
    \     'the first argument number was out of range ' .
    \     '(type() defines ' . arity . ' arguments)'
  endif
endfunction

function! s:_validate_arg_types(args, types, prefix) abort
  let optarg = 0
  let typelen = len(a:types)
  let argslen = len(a:args)
  let i = 0
  while i < argslen
    if i + optarg >= typelen
      if optarg && a:types[-1] is# 'option'
        break
      else
        throw a:prefix . ': too many arguments'
      endif
    endif
    if a:types[i + optarg] is# 'option'
      let optarg += 1
      continue
    endif
    call s:_validate_type(
    \ a:args[i], a:types[i + optarg], a:prefix
    \)
    let i += 1
  endwhile
  if !optarg && i < typelen && a:types[i] isnot# 'option'
    throw a:prefix . ': too few arguments'
  endif
endfunction

function! s:_validate_type(value, expected_type, prefix, ...) abort
  if a:expected_type is# 'any'
    return a:value
  endif
  if type(a:expected_type) is# v:t_list
    let matched = filter(copy(a:expected_type),
    \     's:_validate_type(a:value, v:val, a:prefix, s:NONE) isnot# s:NONE')
    if empty(matched)
      if a:0
        return a:1
      endif
      let expected = s:_type_name(a:expected_type)
      throw a:prefix . ': invalid type arguments were given ' .
      \     '(expected: ' . expected .
      \     ', got: ' . s:_type_name(type(a:value)) . ')'
    endif
    return
  endif
  if type(a:value) isnot# a:expected_type
    if a:0
      return a:1
    endif
    throw a:prefix . ': invalid type arguments were given ' .
    \     '(expected: ' . s:_type_name(a:expected_type) .
    \     ', got: ' . s:_type_name(type(a:value)) . ')'
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
  if type(a:f) is# v:t_func
    return call(a:f, [a:arg])
  else
    return map([a:arg], a:f)[0]
  endif
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
