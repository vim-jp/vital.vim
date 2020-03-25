scriptencoding utf-8

let s:suite = themis#suite('Color')
let s:assert = themis#helper('assert')

function! s:suite.before()
  let s:C = vital#vital#new().import('Color')
endfunction

function! s:suite.rgb()
  call s:assert.equals(s:C.parse('#abcdef').as_rgb_hex(), '#ABCDEF')
  call s:assert.equals(s:C.parse('#abcdef').as_rgb_str(), 'rgb('.0xAB.','.0xCD.','.0xEF.')')
  call s:assert.equals(s:C.parse('#012').as_rgb_hex(), '#001122')
  call s:assert.equals(s:C.parse('#012').as_rgb_str(), 'rgb('.0x00.','.0x11.','.0x22.')')
  call s:assert.equals(s:C.parse('rgb(123, 56, 78)').as_rgb_hex(), '#7B384E')
  call s:assert.equals(s:C.parse('rgb(123, 56, 78)').as_rgb_str(), 'rgb('.0x7B.','.0x38.','.0x4E.')')
  call s:assert.equals(s:C.rgb(255, 255, 255).as_rgb_hex(), '#FFFFFF')
  call s:assert.equals(s:C.rgb(255, 255, 255).as_rgb_str(), 'rgb('.0xFF.','.0xFF.','.0xFF.')')
  call s:assert.equals(s:C.rgb(255, 0, 0).as_rgb_hex(), '#FF0000')
  call s:assert.equals(s:C.rgb(255, 0, 0).as_rgb_str(), 'rgb('.0xFF.','.0x00.','.0x00.')')
  call s:assert.equals(s:C.rgb(0, 0, 0).as_rgb_hex(), '#000000')
  call s:assert.equals(s:C.rgb(0, 0, 0).as_rgb_str(), 'rgb('.0x00.','.0x00.','.0x00.')')
endfunction

function! s:suite.hsl()
  call s:assert.equals(s:C.parse('hsl(210,68%,80%)').as_hsl_str(), 'hsl(210,68%,80%)')
  call s:assert.equals(s:C.parse('hsl(210,100%,7%)').as_hsl_str(), 'hsl(210,100%,7%)')
  call s:assert.equals(s:C.parse('hsl(340,37%,35%)').as_hsl_str(), 'hsl(340,37%,35%)')
  call s:assert.equals(s:C.hsl(0, 0, 100).as_hsl_str(), 'hsl(0,0%,100%)')
  call s:assert.equals(s:C.hsl(0, 100, 50).as_hsl_str(), 'hsl(0,100%,50%)')
  call s:assert.equals(s:C.hsl(0, 0, 0).as_hsl_str(), 'hsl(0,0%,0%)')
endfunction

function! s:suite.xterm()
  for [code, hex] in [
  \ [0, '#000000'],
  \ [1, '#800000'],
  \ [2, '#008000'],
  \ [3, '#808000'],
  \ [4, '#000080'],
  \ [5, '#800080'],
  \ [6, '#008080'],
  \ [7, '#C0C0C0'],
  \ [8, '#808080'],
  \ [9, '#FF0000'],
  \ [10, '#00FF00'],
  \ [11, '#FFFF00'],
  \ [12, '#0000FF'],
  \ [13, '#FF00FF'],
  \ [14, '#00FFFF'],
  \ [15, '#FFFFFF'],
  \]
    call s:assert.equals(s:C.xterm(code).as_rgb_hex(), hex)
  endfor
endfunction

function! s:suite.eq() abort
  for [l, r] in [
\ [s:C.parse('#abcdef'), s:C.parse('rgb('.0xAB.', '.0xCD.', '.0xEF.')')],
\ [s:C.parse('#deadbe'), s:C.parse('rgb('.0xDE.','.0xAD.','.0xBE.')')],
\ [s:C.hsl(210, 100, 7), s:C.parse('hsl(210,100%,7%)')],
\ [s:C.hsl(123, 45, 67), s:C.parse('hsl(123, 45%, 67%)')],
\]
    call s:assert.true(l.eq(r), l.as_rgb_hex() . ' eq ' . r.as_rgb_hex())
    call s:assert.true(r.eq(l), r.as_rgb_hex() . ' eq ' . l.as_rgb_hex())
  endfor
endfunction

function! s:suite.diff() abort
  for [l, r] in [
 \ [s:C.parse('#abcdef'), s:C.parse('hsl(210, 68%, 80%)')],
 \ [s:C.parse('#012'), s:C.parse('hsl(210, 100%, 7%)')],
 \ [s:C.parse('#deadbe'), s:C.parse('rgb('.0xDE.','.0xAD.','.0xBE.')')],
 \]
    call s:assert.compare(l.diff(r), '<', 5, l.as_rgb_hex() . ' diff ' . r.as_rgb_hex())
    call s:assert.compare(r.diff(l), '<', 5, r.as_rgb_hex() . ' diff ' . l.as_rgb_hex())
  endfor
endfunction
