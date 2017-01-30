" random number generator using xorshift128
" http://www.jstatsoft.org/v08/i14/paper

let s:save_cpo = &cpo
set cpo&vim


function! s:_vital_loaded(V) abort
  let s:B = a:V.import('Bitwise')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise']
endfunction


let s:Generator = {}

function! s:Generator.next() abort
  let t = s:B.xor(self._x, s:B.lshift(self._x, 11))
  let w = self._w
  let self._x = self._y
  let self._y = self._z
  let self._z = self._w
  let self._w = s:B.xor(s:B.xor(w, s:B.rshift32(w, 19)), s:B.xor(t, s:B.rshift32(t, 8)))
  return s:B.sign_extension(self._w)
endfunction

" 0x80000000 in 32bit and 0xFFFFFFFF80000000 in 64bit
function! s:Generator.min() abort
  return -2147483648
endfunction

" 0x7FFFFFFF in 32bit/64bit
function! s:Generator.max() abort
  return 2147483647
endfunction

function! s:_fmix32(x) abort
  let x = s:B.and(0xFFFFFFFF, a:x)
  let x = s:B.and(0xFFFFFFFF, 0x85EBCA6B * s:B.xor(x, s:B.rshift(x, 16)))
  let x = s:B.and(0xFFFFFFFF, 0xC2B2AE35 * s:B.xor(x, s:B.rshift(x, 13)))
  return s:B.xor(x, s:B.rshift(x, 16))
endfunction

function! s:Generator.seed(seeds) abort
  let x = 123456789
  for seed in a:seeds
    let x = s:_fmix32(x + seed)
  endfor

  let s = [0, 0, 0, 0]
  for i in range(4)
    let x += 0x9E3779B9
    let s[i] = s:_fmix32(x)
  endfor
  let [self._x, self._y, self._z, self._w] = s
endfunction

function! s:new_generator() abort
  let gen = deepcopy(s:Generator)
  call gen.seed([])
  return gen
endfunction


function! s:_common_generator() abort
  if !exists('s:common_generator')
    let s:common_generator = s:new_generator()
  endif
  return s:common_generator
endfunction

function! s:srand(...) abort
  if a:0 == 0
    let x = has('reltime') ? reltime()[1] : localtime()
  elseif a:0 == 1
    let x = a:1
  else
    throw 'vital: Random.Xor128: srand(): too many arguments'
  endif
  call s:_common_generator().seed([x])
endfunction

function! s:rand() abort
  return s:_common_generator().next()
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
