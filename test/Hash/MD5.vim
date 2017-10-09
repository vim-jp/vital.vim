let s:suite = themis#suite('Hash.MD5')
let s:assert = themis#helper('assert')

function! s:suite.before()
  let s:MD5 = vital#vital#new().import('Hash.MD5')
endfunction

function! s:suite.after()
  unlet! s:MD5
endfunction

function! s:suite.encode() abort
   call s:assert.equal(s:MD5.sum(''), 'd41d8cd98f00b204e9800998ecf8427e')
   call s:assert.equal(s:MD5.sum('a'), '0cc175b9c0f1b6a831c399e269772661')
   call s:assert.equal(s:MD5.sum('abc'), '900150983cd24fb0d6963f7d28e17f72')
   call s:assert.equal(s:MD5.sum('message digest'), 'f96b697d7cb7938d525a2f31aaf161d0')
   call s:assert.equal(s:MD5.sum('abcdefghijklmnopqrstuvwxyz'), 'c3fcd3d76192e4007dfb496cca67e13b')
   call s:assert.equal(s:MD5.sum('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'), 'd174ab98d277d9f5a5611c2c9f419d9f')
   call s:assert.equal(s:MD5.sum('12345678901234567890123456789012345678901234567890123456789012345678901234567890'), '57edf4a22be3c955ac49da2e2107b67a')
endfunction
