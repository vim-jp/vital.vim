
scriptencoding utf-8

let s:suite = themis#suite('CharsetDetector')
let s:assert = themis#helper('assert')

let s:multichars_utf_8 = nr2char(0xE3) . nr2char(0x81) . nr2char(0x82) . nr2char(0xE3) . nr2char(0x81) . nr2char(0x84)
let s:multichars_euc_jp = nr2char(0xA4) . nr2char(0xA2) . nr2char(0xA4) . nr2char(0xA4)
let s:multichars_cp932 = nr2char(0x82) . nr2char(0xA0) . nr2char(0x82) . nr2char(0xA2)
let s:singlechars = "abcdef"

function! s:suite.before()
  let s:CharsetDetector = vital#of('vital').import('CharsetDetector')
endfunction

function! s:suite.after()
  unlet! s:CharsetDetector
endfunction

" echo iconv(s:multichars_utf_8, 'utf-8', 'cp932') == s:multichars_cp932
" echo iconv(s:multichars_cp932, 'cp932', 'utf-8') == s:multichars_utf_8
" echo iconv(s:multichars_euc_jp, 'euc-jp', 'cp932') == s:multichars_cp932

function! s:suite.test_is_utf8()
  call s:assert.equals( s:CharsetDetector.is_utf8(s:multichars_utf_8), 1)
  call s:assert.equals( s:CharsetDetector.of(s:multichars_utf_8), 'utf-8')
endfunction

function! s:suite.test_is_eucjp()
  call s:assert.equals( s:CharsetDetector.is_eucjp(s:multichars_euc_jp), 1)
  call s:assert.equals( s:CharsetDetector.of(s:multichars_euc_jp), 'euc-jp')
endfunction

function! s:suite.test_is_cp932()
  call s:assert.equals( s:CharsetDetector.is_cp932(s:multichars_cp932), 1)
  call s:assert.equals( s:CharsetDetector.of(s:multichars_cp932), 'cp932')
endfunction

function! s:suite.test_is_iso2022jp()
  call s:assert.equals( s:CharsetDetector.is_iso2022jp(s:singlechars), 1)
  call s:assert.equals( s:CharsetDetector.of(s:singlechars), 'iso-2022-jp')
endfunction

