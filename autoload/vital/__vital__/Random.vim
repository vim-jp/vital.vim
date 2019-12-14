let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Bitwise = s:V.import('Bitwise')
endfunction

function! s:_vital_depends() abort
  return [['Random.*'], 'Bitwise']
endfunction

let s:loaded_generator_modules = {}

let s:Random = {}

function! s:Random.next(...) abort
  if a:0
    return map(range(a:1), 'self._generator.next()')
  endif
  return self._generator.next()
endfunction

function! s:Random.seed(seed) abort
  let seed = type(a:seed) == type([]) ? a:seed : [a:seed]
  return self._generator.seed(seed)
endfunction

function! s:Random.generate_canonical() abort
  let b = 32
  let min = self._generator.min() + 0.0
  let r = (self._generator.max() + 0.0) - min + 1.0
  let log2r = float2nr(log(r) / log(2.0))
  let k = max([1, (b + log2r - 1) / log2r])
  let sum = 0.0
  let tmp = 1.0
  while k != 0
    let sum += (self._generator.next() - min) * tmp
    let tmp = tmp * r
    let k -= 1
  endwhile
  return sum / tmp
endfunction

function! s:Random.range(from, ...) abort
  let [from, to] = a:0 ? [a:from, a:1] : [0, a:from]
  let range = to - from
  let base = self.generate_canonical() * range
  return (type(range) == type(0.0) ? base : float2nr(base)) + from
endfunction

function! s:Random.bool() abort
  return self.range(2)
endfunction

function! s:Random.sample(list, ...) abort
  if a:0 == 0
    return a:list[self.range(len(a:list))]
  endif
  let list = copy(a:list)
  let result = []
  for _ in range(a:1)
    let result += [remove(list, self.range(len(list)))]
  endfor
  return result
endfunction

function! s:Random.shuffle(list) abort
  let pos = len(a:list)
  while 1 < pos
    let n = self.range(pos)
    let pos -= 1
    if n != pos
      let [a:list[n], a:list[pos]] = [a:list[pos], a:list[n]]
    endif
  endwhile
  return a:list
endfunction

function! s:make_seed() abort
  let seed = localtime()
  if has('reltime')
    let time = split(reltimestr(reltime()), '\.')
    for n in time
      let seed = s:Bitwise.xor(seed, str2nr(n))
    endfor
  endif
  let seed = s:Bitwise.xor(seed, getpid())
  let seed = s:_seed_from_string(seed, expand('~'))
  return seed
endfunction

function! s:_seed_from_string(seed, str) abort
  let seed = a:seed
  for n in range(len(a:str))
    let seed = s:Bitwise.xor(seed, s:Bitwise.lshift(a:str[n], n % 4))
  endfor
  return seed
endfunction

function! s:new(...) abort
  let generator = a:0 ? a:1 : ''
  " vint: -ProhibitUsingUndeclaredVariable
  let seed = 2 <= a:0 ? a:2 : s:next() " s:next() is defined by execute() below
  " vint: +ProhibitUsingUndeclaredVariable
  let random = deepcopy(s:Random)
  let random._generator = s:_get_generator(generator)
  call random.seed(seed)
  return random
endfunction

function! s:_get_generator(arg) abort
  let arg =
  \ empty(a:arg)
  \ ? matchstr(get(s:V.search('Random.*'), 0, ''), 'Random\.\zs.*$')
  \ : a:arg
  if type(arg) == type('')
    if !has_key(s:loaded_generator_modules, arg)
      let module_name = 'Random.' . arg
      if !s:V.exists(module_name)
        throw printf('vital: Random: the generator "%s" does not exist.', arg)
      endif
      let module = s:V.import(module_name)
      let s:loaded_generator_modules[arg] = module
    endif
    let gen = s:loaded_generator_modules[arg].new_generator()
    return gen
  endif
  if type(arg) == type({})
    return arg
  endif
  throw printf('vital: Random: Invalid generator: %s', string(a:arg))
endfunction

function! s:_common() abort
  if !exists('s:common_random')
    let s:common_random = s:new('', s:make_seed())
  endif
  return s:common_random
endfunction
let s:func_type = type(function('type'))
for s:func in keys(filter(copy(s:Random), 'type(v:val) == s:func_type'))
  execute join([
  \   'function! s:' . s:func . '(...) abort',
  \   '  let r = s:_common()',
  \   '  return call(r.' . s:func . ', a:000, r)',
  \   'endfunction',
  \ ], "\n")
endfor

let &cpo = s:save_cpo
unlet s:save_cpo
