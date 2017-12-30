scriptencoding utf-8

let s:suite = themis#suite('Text.Sexp')
let s:assert = themis#helper('assert')

function! s:suite.before()
  if has('nvim')
    return
  endif
  let s:S = vital#vital#new().import('Text.Sexp')
endfunction

function! s:suite.after()
  silent! unlet! s:S
endfunction

function! s:suite.parse()
  if has('nvim')
    call s:assert.skip('Vital.Text.Sexp: Neovim lua interpreter is not completed yet so skip')
  endif
  if !has('lua') || !exists('*luaeval')
    call s:assert.skip('Vital.Text.Sexp: any function call needs if_lua')
  endif
  call s:assert.equals(
        \ s:S.parse('(a b c)'),
        \ [[{'label': 'identifier', 'col': 2.0, 'matched_text': 'a'}, {'label': 'whitespace', 'col': 3.0, 'matched_text': ' '}, {'label': 'identifier', 'col': 4.0, 'matched_text': 'b'}, {'label': 'whitespace', 'col': 5.0, 'matched_text': ' '}, {'label': 'identifier', 'col': 6.0, 'matched_text': 'c'}]])
endfunction
