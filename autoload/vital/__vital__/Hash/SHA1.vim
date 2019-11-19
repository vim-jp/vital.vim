" Utilities for SHA1.
" Tsuyoshi CHO <Tsuyoshi.CHO@Gmail.com>
" License CC0
" Code:
"   based on RFC 3174 Reference implementation. https://tools.ietf.org/html/rfc3174
"   based on Vim implementation vim-scripts/sha1.vim (Licensed)

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_created(module) abort
  let a:module.name = 'SHA1'
  let a:module.hash_length = s:sha1hashsize * 8 " 160
endfunction

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Bitwise = s:V.import('Bitwise')
  let s:ByteArray = s:V.import('Data.List.Byte')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise', 'Data.List.Byte']
endfunction

function! s:sum(data) abort
  let bytes = s:ByteArray.from_string(a:data)
  return s:sum_raw(bytes)
endfunction

function! s:sum_raw(bytes) abort
  return s:ByteArray.to_hexstring(s:digest_raw(a:bytes))
endfunction

function! s:digest(data) abort
  let bytes = s:ByteArray.from_string(a:data)
  return s:digest_raw(bytes)
endfunction

function! s:digest_raw(bytes) abort
  let bytes = copy(a:bytes)
  let sha = deepcopy(s:sha1context, 1)
  let digest = repeat([0], s:sha1hashsize)

  call sha.init()

  let err = sha.input(bytes)
  if err
    throw printf('vital: Hash.SHA1: input Error %d', err)
  endif

  let err = sha.result(digest)
  if err
    throw printf('vital: Hash.SHA1: result Error %d', err)
  endif

  return digest
endfunction

" enum
let s:success     = 0
" null as 1 / not affect
let s:input_long  = 2 " input data too long
let s:state_error = 3 " called Input after Result

" define
let s:sha1hashsize  = 20 " byte = 160bit (20*8)
let s:sha1blocksize = 64

" struct
let s:sha1context = {
      \ 'intermediatehash'   : repeat([0], s:sha1hashsize / 4),
      \ 'length'             : {
      \   'low'  : 0,
      \   'high' : 0,
      \ },
      \ 'messageblock'       : {
      \   'index' : 0,
      \   'data'  : repeat([0], s:sha1blocksize),
      \ },
      \ 'Computed'           : 0,
      \ 'Corrupted'          : 0,
      \}

function! s:_sha1circular_shift(bits, word) abort
  return s:Bitwise.rotate32l(a:word, a:bits)
endfunction

function! s:sha1context.init() dict abort
  let self.length.low           = 0
  let self.length.high          = 0
  let self.messageblock.index   = 0

  let self.intermediatehash[0]  = 0x67452301
  let self.intermediatehash[1]  = 0xEFCDAB89
  let self.intermediatehash[2]  = 0x98BADCFE
  let self.intermediatehash[3]  = 0x10325476
  let self.intermediatehash[4]  = 0xC3D2E1F0

  let self.Computed  = 0
  let self.Corrupted = 0
endfunction

function! s:sha1context.result(digest) dict abort
  if self.Corrupted
    return self.Corrupted
  endif

  if !self.Computed
    call self.padding()
    for i in range(s:sha1blocksize)
      " message may be sensitive, clear it out
      let self.messageblock.data[i] = 0
    endfor
    let self.length.low  = 0      " and clear length
    let self.length.high = 0
    let self.Computed = 1
  endif

  for i in range(s:sha1hashsize)
    let a:digest[i] = s:Bitwise.uint8(
          \   s:Bitwise.rshift32(
          \     self.intermediatehash[s:Bitwise.rshift32(i, 2)],
          \     8 * (3 - s:Bitwise.and(i, 0x03))
          \   )
          \ )
  endfor

  return s:success
endfunction

function! s:sha1context.input(bytes) dict abort
  if !len(a:bytes)
    return s:success
  endif

  if self.Computed
    let self.Corrupted = s:state_error
    return s:state_error
  endif

  " size set and check
  let self.Corrupted = self.length.sizeset(a:bytes)

  if self.Corrupted
    return self.Corrupted
  endif

  for x in a:bytes
    if self.Corrupted
      break
    endif
    call self.messageblock.push(s:Bitwise.uint8(x))

    if self.messageblock.index == s:sha1blocksize
      call self.process()
    endif
  endfor

  return s:success
endfunction

function! s:sha1context.process() dict abort
  " Constants defined in SHA-1
  let K = [
        \ 0x5A827999,
        \ 0x6ED9EBA1,
        \ 0x8F1BBCDC,
        \ 0xCA62C1D6
        \ ]
  let t = 0                         " Loop counter
  let temp = 0                      " Temporary word value
  let W = repeat([0], 80)           " Word sequence
  let [A, B, C, D, E] = [0, 0, 0, 0, 0] " Word buffers

  "
  "  Initialize the first 16 words in the array W
  "
  for t in range(16)
    let W[t] = s:Bitwise.lshift32(self.messageblock.data[t * 4], 24)
    let W[t] = s:Bitwise.or(W[t], s:Bitwise.lshift32(self.messageblock.data[t * 4 + 1], 16))
    let W[t] = s:Bitwise.or(W[t], s:Bitwise.lshift32(self.messageblock.data[t * 4 + 2], 8))
    let W[t] = s:Bitwise.or(W[t], self.messageblock.data[t * 4 + 3])
  endfor

  for t in range(16, 79)
    let W[t] = s:_sha1circular_shift(1, s:Bitwise.xor(s:Bitwise.xor(s:Bitwise.xor(W[t-3], W[t-8]), W[t-14]), W[t-16]))
  endfor

  let A = self.intermediatehash[0]
  let B = self.intermediatehash[1]
  let C = self.intermediatehash[2]
  let D = self.intermediatehash[3]
  let E = self.intermediatehash[4]

  for t in range(20)
    let temp = s:_sha1circular_shift(5,A) +
          \ s:Bitwise.or(s:Bitwise.and(B, C), s:Bitwise.and(s:Bitwise.invert(B), D)) +
          \ E + W[t] + K[0]
    let E = D
    let D = C
    let C = s:_sha1circular_shift(30,B)
    let B = A
    let A = temp
  endfor

  for t in range(20, 39)
    let temp = s:_sha1circular_shift(5,A) + s:Bitwise.xor(s:Bitwise.xor(B, C), D) + E + W[t] + K[1]
    let E = D
    let D = C
    let C = s:_sha1circular_shift(30,B)
    let B = A
    let A = temp
  endfor

  for t in range(40, 59)
    let temp = s:_sha1circular_shift(5,A) +
          \ s:Bitwise.or(s:Bitwise.or(s:Bitwise.and(B, C), s:Bitwise.and(B, D)), s:Bitwise.and(C, D)) +
          \ E + W[t] + K[2]
    let E = D
    let D = C
    let C = s:_sha1circular_shift(30,B)
    let B = A
    let A = temp
  endfor

  for t in range(60, 79)
    let temp = s:_sha1circular_shift(5,A) +
          \ s:Bitwise.xor(s:Bitwise.xor(B, C), D) + E + W[t] + K[3]
    let E = D
    let D = C
    let C = s:_sha1circular_shift(30,B)
    let B = A
    let A = temp
  endfor

  let self.intermediatehash[0] += A
  let self.intermediatehash[1] += B
  let self.intermediatehash[2] += C
  let self.intermediatehash[3] += D
  let self.intermediatehash[4] += E

  let self.messageblock.index = 0
endfunction

function! s:sha1context.padding() dict abort
  "
  "  Check to see if the current message block is too small to hold
  "  the initial padding bits and length.  If so, we will pad the
  "  block, process it, and then continue padding into a second
  "  block.
  "
  if self.messageblock.index > 55  " >= s:sha1blocksize - 8
    call self.messageblock.push(0x80)
    while self.messageblock.index < s:sha1blocksize
      call self.messageblock.push(0x00)
    endwhile

    call self.process()

    while self.messageblock.index < 56 " < s:sha1blocksize - 8
      call self.messageblock.push(0x00)
    endwhile
  else
    call self.messageblock.push(0x80)
    while self.messageblock.index < 56 " < s:sha1blocksize - 8
      call self.messageblock.push(0x00)
    endwhile
  endif

  "
  "  Store the message length as the last 8 octets
  "
  " as data[-8]..data[-1]
  let self.messageblock.data[56] = s:Bitwise.uint8(s:Bitwise.rshift32(self.length.high, 24))
  let self.messageblock.data[57] = s:Bitwise.uint8(s:Bitwise.rshift32(self.length.high, 16))
  let self.messageblock.data[58] = s:Bitwise.uint8(s:Bitwise.rshift32(self.length.high,  8))
  let self.messageblock.data[59] = s:Bitwise.uint8(                   self.length.high     )
  let self.messageblock.data[60] = s:Bitwise.uint8(s:Bitwise.rshift32(self.length.low , 24))
  let self.messageblock.data[61] = s:Bitwise.uint8(s:Bitwise.rshift32(self.length.low , 16))
  let self.messageblock.data[62] = s:Bitwise.uint8(s:Bitwise.rshift32(self.length.low ,  8))
  let self.messageblock.data[63] = s:Bitwise.uint8(                   self.length.low      )

  call self.process()
endfunction

" message block method
function! s:sha1context.messageblock.push(data) dict abort
  let self.data[self.index] = a:data
  let self.index += 1
endfunction

" data length method
function! s:sha1context.length.sizeset(data) dict abort
  " length as 64bit value  bit length(not byte)
  " if has('num64')
    " system support max 2^64 - 1 item
    " need shift 64bit
    " 64bit work
    " 1. len(data)    = 0x0hhhhhhh   llllllll
    " 2. bitlen       = 0xhhhhhhhl 0xlllllll0 (high,low display) << 3/* 8
    " 3.a low mask    =            0xlllllll0 and(x,0xffffffff)
    " 3.b high shift  =            0xhhhhhhhl >> 32
  " else
    " system support max 2^32 - 1 item
    " work only shift 32bit
    " 32bit work
    " 1. len(data)    = 0xllllllll
    "(2. bitlen       = 0xlllllll0 << 3/* 8)
    " 3.a low mask    = 0xlllllll0 << 3/* 8, and(x,0xffffffff)
    " 3.b high shift  = 0x0000000l >> (32 - 3)
  " endif
  " 32/64bit work use shift
  let self.high = s:Bitwise.uint32(s:Bitwise.rshift(len(a:data), 32 - 3))
  let self.low  = s:Bitwise.uint32(s:Bitwise.lshift(len(a:data),      3))

  " SHA1 2^64 - 1 overflow check
  " 0xh0000000 is not 0, then overflow it(byte data are Vim List;it can contains 2^64 - 1 item)
  if (has('num64') && (0 != s:Bitwise.uint32(s:Bitwise.rshift(len(a:data), 32 + (32 - 3)))))
    let self.high = 0
    let self.low  = 0
    return s:input_long
  endif
  return s:success
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
