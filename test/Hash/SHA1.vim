let s:suite = themis#suite('Hash.SHA1')
let s:assert = themis#helper('assert')

function! s:suite.before()
  let s:SHA1 = vital#vital#new().import('Hash.SHA1')
endfunction

function! s:suite.after()
  unlet! s:SHA1
endfunction

function! s:suite.prop() abort
   call s:assert.is_string(s:SHA1.name)
   call s:assert.is_number(s:SHA1.hash_length)
endfunction

function! s:suite.encode() abort
   call s:assert.equal(s:SHA1.sum(''), 'da39a3ee5e6b4b0d3255bfef95601890afd80709')
   call s:assert.equal(s:SHA1.sum('a'), '86f7e437faa5a7fce15d1ddcb9eaeaea377667b8')
   call s:assert.equal(s:SHA1.sum('abc'), 'a9993e364706816aba3e25717850c26c9cd0d89d')
   call s:assert.equal(s:SHA1.sum('message digest'), 'c12252ceda8be8994d5fa0290a47231c1d16aae3')
   call s:assert.equal(s:SHA1.sum('abcdefghijklmnopqrstuvwxyz'), '32d10c7b8cf96570ca04ce37f2a19d84240d3a89')
   call s:assert.equal(s:SHA1.sum('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'), '761c457bf73b14d27e9e9265c46f4b4dda11f940')
   call s:assert.equal(s:SHA1.sum('12345678901234567890123456789012345678901234567890123456789012345678901234567890'), '50abf5706a150990a08b2c5ea40fa0e585554732')

   " RFC Test Driver's testdata
   let s:TEST1   = 'abc'
   let s:TEST2a  = 'abcdbcdecdefdefgefghfghighijhi'
   let s:TEST2b  = 'jkijkljklmklmnlmnomnopnopq'
   let s:TEST2   = s:TEST2a . s:TEST2b
   let s:TEST3   = 'a'
   let s:TEST4a  = '01234567012345670123456701234567'
   let s:TEST4b  = '01234567012345670123456701234567'
   " an exact multiple of 512 bits
   let s:TEST4   = s:TEST4a . s:TEST4b
   let s:testarray = [
         \ s:TEST1,
         \ s:TEST2,
         \ s:TEST3,
         \ s:TEST4
         \ ]
   " original result
   " let s:resultarray = [
   "      \ 'a9993e364706816aba3e25717850c26c9cd0d89d',
   "      \ '84983e441c3bd26ebaae4aa1f95129e5e54670f1',
   "      \ '34aa973cd4c4daa4f61eeb2bdbad27316534016f',
   "      \ 'dea356a2cddd90c7a7ecedc5ebb563934f460452'
   "      \ ]

   " other SHA1 test site generate result
   let s:resultarray = [
         \ 'a9993e364706816aba3e25717850c26c9cd0d89d',
         \ '84983e441c3bd26ebaae4aa1f95129e5e54670f1',
         \ '86f7e437faa5a7fce15d1ddcb9eaeaea377667b8',
         \ 'e0c094e867ef46c350ef54a7f59dd60bed92ae83'
         \]

   call s:assert.equal(s:SHA1.sum(s:testarray[0]),s:resultarray[0])
   call s:assert.equal(s:SHA1.sum(s:testarray[1]),s:resultarray[1])
   call s:assert.equal(s:SHA1.sum(s:testarray[2]),s:resultarray[2])
   call s:assert.equal(s:SHA1.sum(s:testarray[3]),s:resultarray[3])


   " Exxtend Interface test
   " test data
   let exttest_string       = 'abc'
   let exttest_bytelist     = [0x61, 0x62, 0x63]
   let exttest_hashstring   = 'a9993e364706816aba3e25717850c26c9cd0d89d'
   let exttest_hashbytelist = [
         \ 0xa9, 0x99, 0x3e, 0x36, 0x47, 0x06, 0x81, 0x6a, 0xba, 0x3e,
         \ 0x25, 0x71, 0x78, 0x50, 0xc2, 0x6c, 0x9c, 0xd0, 0xd8, 0x9d
         \]

   " test sum        input string   output hashstring
   call s:assert.equal(s:SHA1.sum(exttest_string),         exttest_hashstring)
   " test sum_raw    input bytelist output hashstring
   call s:assert.equal(s:SHA1.sum_raw(exttest_bytelist),   exttest_hashstring)
   " test digest     input string   output hash byte list
   call s:assert.equal(s:SHA1.digest(exttest_string),      exttest_hashbytelist)
   " test digest_raw input bytelist output hash byte list
   call s:assert.equal(s:SHA1.digest_raw(exttest_bytelist),exttest_hashbytelist)
endfunction
