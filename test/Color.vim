scriptencoding utf-8

let s:suite = themis#suite('Color')
let s:assert = themis#helper('assert')

function! s:suite.before()
  let s:C = vital#vital#new().import('Color')
  " need for v:colornames
  silent! colorscheme default
endfunction

function! s:suite.rgb()
  call s:assert.equals(s:C.parse('#abcdef').as_rgb_hex(), '#ABCDEF')
  call s:assert.equals(s:C.parse('#abcdef').as_rgb_str(), 'rgb('.0xAB.','.0xCD.','.0xEF.')')
  call s:assert.equals(s:C.parse('#012').as_rgb_hex(), '#001122')
  call s:assert.equals(s:C.parse('#012').as_rgb_str(), 'rgb('.0x00.','.0x11.','.0x22.')')
  call s:assert.equals(s:C.parse('rgb(123, 56, 78)').as_rgb_hex(), '#7B384E')
  call s:assert.equals(s:C.parse('rgb(123, 56, 78)').as_rgb_str(), 'rgb('.0x7B.','.0x38.','.0x4E.')')
  call s:assert.equals(s:C.parse('rgb(100%, 0%, 0%)').as_rgb_hex(), '#FF0000')
  call s:assert.equals(s:C.parse('rgb(100%, 0%, 0%)').as_rgb_str(), 'rgb('.0xFF.','.0x00.','.0x00.')')
  call s:assert.equals(s:C.rgb(255, 255, 255).as_rgb_hex(), '#FFFFFF')
  call s:assert.equals(s:C.rgb(255, 255, 255).as_rgb_str(), 'rgb('.0xFF.','.0xFF.','.0xFF.')')
  call s:assert.equals(s:C.rgb(255, 0, 0).as_rgb_hex(), '#FF0000')
  call s:assert.equals(s:C.rgb(255, 0, 0).as_rgb_str(), 'rgb('.0xFF.','.0x00.','.0x00.')')
  call s:assert.equals(s:C.rgb(0, 0, 0).as_rgb_hex(), '#000000')
  call s:assert.equals(s:C.rgb(0, 0, 0).as_rgb_str(), 'rgb('.0x00.','.0x00.','.0x00.')')
endfunction

function! s:suite.color_name()
  call s:assert.equals(s:C.parse('Yellow').as_rgb_hex(), '#FFFF00')
  call s:assert.equals(s:C.parse('ForestGreen').as_rgb(), [34.0, 139.0, 34.0])
  call s:assert.equals(s:C.parse('Forest Green').as_rgb(), [34.0, 139.0, 34.0])
  call s:assert.equals(s:C.parse('Snow').as_rgb(), [255.0, 250.0, 250.0])
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

function! s:suite.distance() abort
  for [l, r] in [
 \ [s:C.parse('#abcdef'), s:C.parse('hsl(210, 68%, 80%)')],
 \ [s:C.parse('#012'), s:C.parse('hsl(210, 100%, 7%)')],
 \ [s:C.parse('#deadbe'), s:C.parse('rgb('.0xDE.','.0xAD.','.0xBE.')')],
 \]
    call s:assert.compare(l.distance(r), '<', 3, l.as_rgb_hex() . ' distance ' . r.as_rgb_hex())
    call s:assert.compare(r.distance(l), '<', 3, r.as_rgb_hex() . ' distance ' . l.as_rgb_hex())
  endfor
endfunction

function! s:suite.error_parse()
  for l:V in [
  \ 0,
  \ function('function'),
  \ [],
  \ {},
  \ 0.0,
  \ v:false,
  \ v:null,
  \ test_null_job(),
  \ test_null_channel(),
  \] + (exists('*test_null_blob') ? [test_null_blob()] : []) + [
  \ '',
  \ '#',
  \ '#d',
  \ '#de',
  \ '#dead',
  \ '#deadb',
  \ '#deadbee',
  \ '#deadbeef',
  \ 'd',
  \ 'de',
  \ 'dea',
  \ 'dead',
  \ 'deadb',
  \ 'deadbe',
  \ 'deadbee',
  \ 'deadbeef',
  \ '0xc0ffee',
  \ 'rgb(-1%,0%,0%)',
  \ 'rgb(-2%,0%,0%)',
  \ 'rgb(0%,-1%,0%)',
  \ 'rgb(0%,-2%,0%)',
  \ 'rgb(0%,0%,-1%)',
  \ 'rgb(0%,0%,-2%)',
  \ 'rgb(101%,0%,0%)',
  \ 'rgb(102%,0%,0%)',
  \ 'rgb(0%,101%,0%)',
  \ 'rgb(0%,102%,0%)',
  \ 'rgb(0%,0%,101%)',
  \ 'rgb(0%,0%,102%)',
  \ 'hsl(0,0,0)',
  \ 'rgb(0,0,0);',
  \ 'hsl(0,0%,0%);',
  \ 'unknown_color_name',
  \]
    try
      call s:C.parse(l:V)
    catch /vital: Color:/
      call s:assert.true(1, string(l:V) . ' should not be parsed')
    endtry
  endfor
endfunction

function! s:suite.error_rgb()
  for rgb in [
  \ repeat([0], 3),
  \ repeat([function('function')], 3),
  \ repeat([[]], 3),
  \ repeat([{}], 3),
  \ repeat([0.0], 3),
  \ repeat([v:false], 3),
  \ repeat([v:null], 3),
  \ repeat([test_null_job()], 3),
  \ repeat([test_null_channel()], 3),
  \] + (exists('*test_null_blob') ? [repeat([test_null_blob()], 3)] : []) + [
  \ [-1, 0, 0],
  \ [-2, 0, 0],
  \ [0, -1, 0],
  \ [0, -2, 0],
  \ [0, 0, -1],
  \ [0, 0, -2],
  \ [256, 0, 0],
  \ [257, 0, 0],
  \ [0, 256, 0],
  \ [0, 257, 0],
  \ [0, 0, 256],
  \ [0, 0, 257],
  \]
    try
      call s:C.rgb(rgb[0], rgb[1], rgb[2])
    catch /vital: Color: rgb():/
      call s:assert.true(1, 'rgb() disallow ' . string(rgb))
    endtry
  endfor
endfunction

function! s:suite.error_hsl()
  for hsl in [
  \ repeat([0], 3),
  \ repeat([function('function')], 3),
  \ repeat([[]], 3),
  \ repeat([{}], 3),
  \ repeat([0.0], 3),
  \ repeat([v:false], 3),
  \ repeat([v:null], 3),
  \ repeat([test_null_job()], 3),
  \ repeat([test_null_channel()], 3),
  \] + (exists('*test_null_blob') ? [repeat([test_null_blob()], 3)] : []) + [
  \ [-1, 0, 0],
  \ [-2, 0, 0],
  \ [0, -1, 0],
  \ [0, -2, 0],
  \ [0, 0, -1],
  \ [0, 0, -2],
  \ [361, 0, 0],
  \ [362, 0, 0],
  \ [0, 101, 0],
  \ [0, 102, 0],
  \ [0, 0, 101],
  \ [0, 0, 102],
  \]
    try
      call s:C.hsl(hsl[0], hsl[1], hsl[2])
    catch /vital: Color: hsl():/
      call s:assert.true(1, 'hsl() disallow ' . string(hsl))
    endtry
  endfor
endfunction

function! s:suite.error_xterm()
  for l:Value in [
  \ function('function'),
  \ [],
  \ {},
  \ 0.0,
  \ v:false,
  \ v:null,
  \ test_null_job(),
  \ test_null_channel(),
  \] + (exists('*test_null_blob') ? [test_null_blob()] : []) + [
  \ -2,
  \ -1,
  \ 256,
  \ 257,
  \]
    try
      call s:C.xterm(l:Value)
    catch /vital: Color: xterm():/
      call s:assert.true(1, 'xterm() disallow ' . string(l:Value))
    endtry
  endfor
endfunction
