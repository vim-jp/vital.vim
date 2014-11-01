let s:save_cpo = &cpo
set cpo&vim

let s:OPERATOR_LIST = [
\  '+', '-', '*', '/', '%', '.',
\  '==', '==#', '==?',
\  '!=', '!=#', '!=?',
\  '>',  '>#',  '>?',
\  '>=', '>=#', '>=?',
\  '<',  '<#',  '<?',
\  '<=', '<=#', '<=?',
\  '=~', '=~#', '=~?',
\  '!~', '!~#', '!~?',
\  'is', 'is#', 'is?',
\  'isnot', 'isnot#', 'isnot?',
\  '||', '&&',
\]

let s:is_binding_supported =
\   704 <= v:version || (v:version == 703 && has('patch560'))

let s:closures = {}
let s:mark_to_sweep = {}
let s:current_function_id = 0

let s:Closure = {
\   '_arglist': [],
\   '_context': {},
\ }

function! s:_new(function, arglist, context)
  let closure = deepcopy(s:Closure)
  let closure._function = a:function
  let closure._arglist = a:arglist
  let closure._context = a:context
  return closure
endfunction

function! s:Closure.call(...)
  return self.apply(a:000)
endfunction

function! s:Closure.apply(arglist)
  return call(self._function, self._arglist + a:arglist, self._context)
endfunction

function! s:Closure.with_args(...)
  return self.with_arglist(a:000)
endfunction

function! s:Closure.with_arglist(arglist)
  if empty(a:arglist)
    return self
  endif
  return s:_new(
  \   self._function,
  \   self._arglist + a:arglist,
  \   self._context)
endfunction

function! s:Closure.with_context(context)
  if type(a:context) != type({})
    return self
  endif
  return s:_new(self._function, self._arglist, a:context)
endfunction

function! s:Closure.with_param(param_list)
  let [arglist, context] = s:_get_arglist_and_context(a:param_list)
  if empty(arglist) && type(context) != type({})
    return self
  endif
  if type(context) != type({})
    unlet context
    let context = self._context
  endif
  return s:_new(self._function, self._arglist + arglist, context)
endfunction

function! s:Closure.compose(...)
  return s:compose(a:000 + [self])
endfunction

function! s:Closure.to_function(...)
  if !has_key(self, '_function_id')
    let self._function_id = s:_create_function_id()
    let s:closures[self._function_id] = self
  endif
  let self._limit = a:0 ? a:1 : 0
  let name = s:_function_name(self._function_id)
  call s:_make_function(name, self._function_id)
  return s:_sfunc(name)
endfunction

function! s:Closure.delete_function()
  let id = get(self, '_function_id', 0)
  let funcname = 's:' . s:_function_name(id)
  if has_key(s:mark_to_sweep, id)
    call remove(s:mark_to_sweep, id)
  endif
  if exists('*' . funcname)
    try
      execute 'delfunction ' . funcname
    catch /^Vim(delfunction):E131:/
      let s:mark_to_sweep[id] = self
    endtry
  endif
  if has_key(s:closures, id)
    call remove(s:closures, id)
  endif
endfunction

function! s:Closure._decrease()
  if get(self, '_limit', 0) <= 0
    return
  endif
  let self._limit -= 1
  if self._limit == 0
    call self.delete_function()
    call remove(self, '_limit')
  endif
endfunction

function! s:_create_function_id()
  let s:current_function_id += 1
  return s:current_function_id
endfunction

function! s:_function_name(id)
  return printf('_function_%d', a:id)
endfunction

function! s:_make_function(name, id)
  execute printf(join([
  \   'function s:%s(...)',
  \   '  let closure = get(s:closures, %s)',
  \   '  if !s:is_closure(closure)',
  \   '    throw s:error("This function has been deleted")',
  \   '  endif',
  \   '  let Result = closure.apply(a:000)',
  \   '  call closure._decrease()',
  \   '  return Result',
  \   'endfunction',
  \ ], "\n"), a:name, a:id)
endfunction


function! s:from_funcref(function, ...)
  let closure = deepcopy(s:Closure)
  let closure._function = a:function
  return closure.with_param(a:000)
endfunction

function! s:from_funcname(funcname, ...)
  let funcname = a:funcname[0] ==# '*' ? a:funcname[1 :] : a:funcname
  return call('s:from_funcref', [function(funcname)] + a:000)
endfunction

function! s:from_expr(expr, ...)
  let expr = a:expr[0] ==# '=' ? a:expr[1 :] : a:expr
  let binding = s:_get_binding(a:000)
  let context = {'binding': binding, 'expr': expr}
  return s:from_funcref(s:_sfunc('_eval'), context)
endfunction

function! s:from_command(command, ...)
  let binding = s:_get_binding(a:000)
  let command =
  \   type(a:command) == type([])
  \     ? join(a:command, "\n")
  \     : a:command
  let context = {'binding': binding, 'command': command}
  return s:from_funcref(s:_sfunc('_execute'), context)
endfunction

function! s:from_operator(op)
  if !s:_is_operator(a:op)
    throw s:error('%s is not an operator', string(a:op))
  endif
  return s:from_expr(printf('a:1%sa:2', a:op))
endfunction

function! s:from_method(obj, method)
  return s:from_funcref(a:obj[a:method], a:obj)
endfunction

function! s:build(callable, ...)
  call s:sweep_functions()  " Automatically delete garbages
  let t = type(a:callable)
  if s:is_closure(a:callable)
    return a:callable.with_param(a:000)
  elseif t == type(function('type'))
    return call('s:from_funcref', [a:callable] + a:000)
  elseif t == type('')
    if s:_is_operator(a:callable)
      return s:from_operator(a:callable).with_param(a:000)
    elseif a:callable[0] ==# '*'
      return call('s:from_funcname', [a:callable[1 :]] + a:000)
    elseif a:callable[0] ==# ':'
      return call('s:from_command', [a:callable[1 :]] + a:000)
    elseif a:callable[0] ==# '='
      return call('s:from_expr', [a:callable[1 :]] + a:000)
    endif
  elseif t == type([])
    for C in a:callable
      if type(C) != type('') || C[0] !=# ':'
        return call('s:build', a:callable)
      endif
      unlet C
    endfor
    return call('s:from_command', [a:callable] + a:000)
  endif
  throw s:error('Can not treat as callable: %s', string(a:callable))
endfunction

function! s:call(callable, ...)
  return s:apply(a:callable, a:000)
endfunction

function! s:apply(callable, ...)
  let closure = call('s:build', [a:callable] + a:000)
  return closure.call()
endfunction

function! s:compose(callables)
  if empty(a:callables)
    return s:from_command('')
  endif
  let callables = reverse(copy(a:callables))
  let closure = s:build(remove(callables, 0))
  for C in callables
    let next = s:build(C)
    let context = {'first': closure, 'second': next}
    let closure = s:from_funcref(s:_sfunc('_chain'), context)
    unlet C
  endfor
  return closure
endfunction

function! s:is_closure(expr)
  return type(a:expr) == type({}) &&
  \      has_key(a:expr, 'call') &&
  \      type(a:expr.call) == type(function('call')) &&
  \      a:expr.call == s:Closure.call
endfunction

function! s:is_callable(expr)
  let t = type(a:expr)
  return
  \   s:is_closure(a:expr) ||
  \   t == type(function('type')) ||
  \   (t == type('') && (
  \     s:_is_operator(a:expr) || a:expr[0] =~# '[*:=]'
  \   )) ||
  \   (t == type([]) && (
  \     empty(a:expr) || s:is_callable(a:expr[0])
  \   ))
endfunction

function! s:is_binding_supported()
  return s:is_binding_supported
endfunction

function! s:sweep_functions()
  for closure in values(s:mark_to_sweep)
    call closure.delete_function()
  endfor
endfunction


function! s:_get_arglist_and_context(args)
  let arglist = []
  let context = 0
  for arg in a:args
    let t = type(arg)
    if t == type([])
      call extend(arglist, arg)
    elseif t == type({})
      unlet context
      let context = arg
    endif
    unlet arg
  endfor
  return [arglist, context]
endfunction

function! s:_get_binding(args)
  if empty(a:args)
    return {}
  endif
  let arg = a:args[0]
  let t = type(arg)
  if t == type({})
    return arg
  endif
  if t == type([])
    let binding = {}
    for b in arg
      if t == type({})
        call extend(binding, b)
      else
        throw s:error('{binding} must be a Dictionary: %s', string(a:args))
      endif
      unlet b
    endfor
    return binding
  endif
  throw s:error('{binding} must be a Dictionary: %s', string(a:args))
endfunction

function! s:_is_operator(str)
  return 0 <= index(s:OPERATOR_LIST, a:str)
endfunction

function! s:_eval(...) dict
  for s:key in keys(self.binding)
    if s:key !=# 'self'
      let {s:key} = self.binding[s:key]
    endif
  endfor

  try
    return eval(self.expr)
  finally
    call s:_move(self.binding, l:)
  endtry
endfunction

function! s:_execute(...) dict
  for s:key in keys(self.binding)
    if s:key !=# 'self'
      let {s:key} = self.binding[s:key]
    endif
  endfor

  try
    execute self.command
  finally
    call s:_move(self.binding, l:)
  endtry
endfunction

function! s:_chain(...) dict
  return self.second.call(self.first.apply(a:000))
endfunction

function! s:_move(l, binding)
  if !s:is_binding_supported
    return
  endif
  call filter(a:l, 'v:key ==# "self"')
  call extend(a:l, filter(copy(a:binding), 'v:key !=# "self"'))
endfunction

function! s:_is_funcname(name)
  let builtin_func = '\l\w+'
  let global_func = '%(\u|g:\u|)\w+'
  let script_func = '%(s:|\<SNR\>\d+_)\w+'
  let autoload_func = '\h\w*%(#\w+)+'
  let numbered_func = '\d+'
  let func_pat = '\v^%(' . join([
  \   builtin_func,
  \   global_func,
  \   script_func,
  \   autoload_func,
  \   numbered_func,
  \ ], '|') . ')$'
  return a:name =~# func_pat
endfunction

function! s:_function_exists(name)
  try
    return s:_is_funcname(a:name) && exists('*' . a:name)
  catch
  endtry
  return 0
endfunction

function! s:_sfunc(name)
  return function(matchstr(expand('<sfile>'), '<SNR>\d\+_\ze_\w\+$') . a:name)
endfunction

function! s:error(message, ...)
  let mes = printf('vital: Data.Closure: %s', a:message)
  if a:0
    let mes = call('printf', [mes] + a:000)
  endif
  return mes
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
