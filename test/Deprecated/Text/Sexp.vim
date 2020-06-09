scriptencoding utf-8

let s:suite = themis#suite('Deprecated.Text.Sexp')
let s:assert = themis#helper('assert')
let s:has_lua = has('lua') && exists('*luaeval')

function! s:suite.before()
  if !s:has_lua
    return
  endif
  let s:S = vital#vital#new().import('Deprecated.Text.Sexp')
endfunction

function! s:suite.after()
  unlet! s:S
endfunction

function! s:suite.parse()
  if !s:has_lua
    call s:assert.skip('Vital.Deprecated.Text.Sexp: any function call needs if_lua')
  endif
  call s:assert.equals(
        \ s:S.parse('(a b c)'),
        \ [[{'label': 'identifier', 'col': 2.0, 'matched_text': 'a'}, {'label': 'whitespace', 'col': 3.0, 'matched_text': ' '}, {'label': 'identifier', 'col': 4.0, 'matched_text': 'b'}, {'label': 'whitespace', 'col': 5.0, 'matched_text': ' '}, {'label': 'identifier', 'col': 6.0, 'matched_text': 'c'}]])
endfunction
