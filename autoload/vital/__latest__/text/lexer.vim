
let s:save_cpo = &cpo
set cpo&vim

function! s:_is_string(expr) "{{{
  return type("") == type(a:expr)
endfunction "}}}
function! s:_is_list(expr) "{{{
  return type([]) == type(a:expr)
endfunction "}}}
function! s:_token(list) "{{{
  if s:_is_list(a:list)
    if len(a:list) < 2 | call s:_exception('too few arguments.') | endif
    if 2 < len(a:list) | call s:_exception('too many arguments.') | endif
    if ! s:_is_string(a:list[0]) | call s:_exception('element of list is not string.') | endif
    if ! s:_is_string(a:list[1]) | call s:_exception('element of list is not string.') | endif
    let tkn = { 'label' : a:list[0], 'regex' : a:list[1] }
    return tkn
  else
    call s:_exception('first argument is not list.')
  endif
endfunction "}}}
function! s:_exception(msg) "{{{
  throw printf('[Text.Lexer] %s', a:msg)
endfunction "}}}
function! s:lexer(patterns) "{{{
  let obj = { 'tokens' : [] }
  for e in a:patterns
    let obj.tokens += [(s:_token(e))]
  endfor
  function! obj.exec(string) dict "{{{
    let match_tokens = []
    let idx = 0
    while idx < len(a:string)
      let best_tkn = {}
      for tkn in self.tokens
        let matched_text = matchstr(a:string[(idx):],'^' . tkn.regex)
        if ! empty(matched_text)
          let best_tkn['label'] = tkn.label
          let best_tkn['matched_text'] = matched_text
          let best_tkn['col'] = idx
          break
        endif
      endfor
      if best_tkn == {}
        call s:_exception(printf('can not match. col:%d',idx))
      else
        let idx += len(best_tkn.matched_text)
        let match_tokens += [best_tkn]
      endif
    endwhile
    return match_tokens
  endfunction "}}}
  return deepcopy(obj)
endfunction "}}}

function! s:simple_parser(expr) "{{{
  let obj = { 'expr' : a:expr, 'idx' : 0, 'tokens' : [] }
  function! obj.end() dict "{{{
    return len(self.expr) <= self.idx
  endfunction "}}}
  function! obj.next() dict "{{{
    if self.end()
      call s:_exception('Already end of tokens.')
    else
      return self.expr[self.idx]
    endif
  endfunction "}}}
  function! obj.next_is(label) dict "{{{
    return self.next().label ==# a:label
  endfunction "}}}
  function! obj.consume() dict "{{{
    if ! self.end()
      let next = self.next()
      let self.idx += 1
    else
      call s:_exception('Already end of tokens.')
    endif
    return next
  endfunction "}}}
  return deepcopy(obj)
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
