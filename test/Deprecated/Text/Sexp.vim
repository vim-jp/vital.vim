scriptencoding utf-8

let s:suite = themis#suite('Deprecated.Text.Sexp')
let s:assert = themis#helper('assert')

function! s:suite.before()
  let s:S = vital#vital#new().import('Deprecated.Text.Sexp')
endfunction

function! s:suite.after()
  unlet! s:S
endfunction

function! s:suite.parse()
  if !has('lua') || !exists('*luaeval')
    call s:assert.skip('Vital.Deprecated.Text.Sexp: any function call needs if_lua')
  endif
  call s:assert.equals(
        \ s:S.parse('(a b c)'),
        \ [[{'label': 'identifier', 'col': 2, 'matched_text': 'a'}, {'label': 'whitespace', 'col': 3, 'matched_text': ' '}, {'label': 'identifier', 'col': 4, 'matched_text': 'b'}, {'label': 'whitespace', 'col': 5, 'matched_text': ' '}, {'label': 'identifier', 'col': 6, 'matched_text': 'c'}]])
endfunction
