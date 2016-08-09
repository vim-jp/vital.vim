" Mersenne Twister, a very long-period and high-order of equidistribution pseudo random number generator.
"
" Ported from https://github.com/ynkdir/vim-funlib/blob/master/autoload/random/mt19937ar.vim
" originally written by Yukihiro Nakadaira (@ynkdir).
"
" Original header is below:
"
" Mersenne Twister
" http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/emt.html
" http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/MT2002/emt19937ar.html
" This is a port of mt19937ar.c
" Last Change:  2010-08-17
" Maintainer:   Yukihiro Nakadaira <yukihiro.nakadaira@gmail.com>
" Original Copyright:
"   A C-program for MT19937, with initialization improved 2002/1/26.
"   Coded by Takuji Nishimura and Makoto Matsumoto.
"
"   Before using, initialize the state by using init_genrand(seed)
"   or init_by_array(init_key, key_length).
"
"   Copyright (C) 1997 - 2002, Makoto Matsumoto and Takuji Nishimura,
"   All rights reserved.
"
"   Redistribution and use in source and binary forms, with or without
"   modification, are permitted provided that the following conditions
"   are met:
"
"     1. Redistributions of source code must retain the above copyright
"        notice, this list of conditions and the following disclaimer.
"
"     2. Redistributions in binary form must reproduce the above copyright
"        notice, this list of conditions and the following disclaimer in the
"        documentation and/or other materials provided with the distribution.
"
"     3. The names of its contributors may not be used to endorse or promote
"        products derived from this software without specific prior written
"        permission.
"
"   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
"   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
"   A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
"   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
"   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
"   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
"   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
"   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
"   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
"   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

let s:save_cpo = &cpo
set cpo&vim


function! s:_vital_loaded(V) abort
  let s:B = a:V.import('Bitwise')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise']
endfunction


let s:Generator = {}

function! s:Generator.seed(seeds) abort
  let self._N = 624
  let self._M = 397
  let self._MATRIX_A = 0x9908b0df
  let self._UPPER_MASK = 0x80000000
  let self._LOWER_MASK = 0x7fffffff

  let self._mt = repeat([0], self._N)
  let self._mti = self._N + 1
  call s:_init_by_array(self, a:seeds)
endfunction

" 0x80000000 in 32bit and 0xFFFFFFFF80000000 in 64bit
function! s:Generator.min() abort
  return -2147483648
endfunction

" 0x7FFFFFFF in 32bit/64bit
function! s:Generator.max() abort
  return 2147483647
endfunction

function! s:_init_genrand(g, s) abort
  let a:g._mt[0] = a:s
  let a:g._mti = 1
  while a:g._mti < a:g._N
    let a:g._mt[a:g._mti] = 1812433253 * s:B.xor(a:g._mt[a:g._mti-1], s:B.rshift32(a:g._mt[a:g._mti-1], 30)) + a:g._mti
    let a:g._mti += 1
  endwhile
endfunction

function! s:_init_by_array(g, init_key) abort
  let key_length = len(a:init_key)
  call s:_init_genrand(a:g, 19650218)
  let i = 1
  let j = 0
  let k = a:g._N > key_length ? a:g._N : key_length
  while k
    let a:g._mt[i] = s:B.xor(a:g._mt[i], s:B.xor(a:g._mt[i-1], s:B.rshift32(a:g._mt[i-1], 30)) * 1664525) + a:init_key[j] + j
    let i += 1
    let j += 1
    if i >= a:g._N
      let a:g._mt[0] = a:g._mt[a:g._N-1]
      let i = 1
    endif
    if j >= key_length
      let j = 0
    endif
    let k -= 1
  endwhile
  let k = a:g._N - 1
  while k
    let a:g._mt[i] = s:B.xor(a:g._mt[i], s:B.xor(a:g._mt[i-1], s:B.rshift32(a:g._mt[i-1], 30)) * 1566083941) - i
    let i += 1
    if i >= a:g._N
      let a:g._mt[0] = a:g._mt[a:g._N-1]
      let i = 1
    endif
    let k -= 1
  endwhile

  let a:g._mt[0] = 0x80000000
endfunction

function! s:Generator.next() abort
  let mag01 = [0, self._MATRIX_A]

  if self._mti >= self._N
    if self._mti == self._N + 1
      call self._init_genrand(self, 5489)
    endif

    let kk = 0
    while kk < self._N - self._M
      let y = s:B.or(s:B.and(self._mt[kk], self._UPPER_MASK), s:B.and(self._mt[kk+1], self._LOWER_MASK))
      let self._mt[kk] = s:B.xor(s:B.xor(self._mt[kk+self._M], s:B.rshift32(y, 1)), mag01[y % 2])
      let kk += 1
    endwhile
    while kk < self._N - 1
      let y = s:B.or(s:B.and(self._mt[kk], self._UPPER_MASK), s:B.and(self._mt[kk+1], self._LOWER_MASK))
      let self._mt[kk] = s:B.xor(s:B.xor(self._mt[kk+(self._M-self._N)], s:B.rshift32(y, 1)), mag01[y % 2])
      let kk += 1
    endwhile
    let y = s:B.or(s:B.and(self._mt[self._N-1], self._UPPER_MASK), s:B.and(self._mt[0], self._LOWER_MASK))
    let self._mt[self._N-1] = s:B.xor(s:B.xor(self._mt[self._M-1], s:B.rshift32(y, 1)), mag01[y % 2])

    let self._mti = 0
  endif

  let y = self._mt[self._mti]
  let self._mti += 1

  let y = s:B.xor(y, s:B.rshift32(y, 11))
  let y = s:B.xor(y, s:B.and(s:B.lshift(y, 7), 0x9d2c5680))
  let y = s:B.xor(y, s:B.and(s:B.lshift(y, 15), 0xefc60000))
  let y = s:B.xor(y, s:B.rshift32(y, 18))

  return s:B.sign_extension(y)
endfunction

function! s:new_generator() abort
  let gen = deepcopy(s:Generator)
  call gen.seed([0x123, 0x234, 0x345, 0x456])
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
    throw 'vital: Random.Mt19937ar: srand(): too many arguments'
  endif
  call s:_common_generator().seed([x])
endfunction

function! s:rand() abort
  return s:_common_generator().next()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
