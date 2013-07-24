let s:save_cpo = &cpo
set cpo&vim


function! s:_exception(msg)
  throw printf('[Text.Parser] %s', a:msg)
endfunction


let s:obj = { '_idx' : 0, '_tokens' : [], '_ignore_labels' : [] }

function! s:obj.config(dict) dict
  if has_key(a:dict,'ignore_labels')
    let self._ignore_labels = a:dict.ignore_labels
  endif
  return self
endfunction

function! s:obj.end() dict
  return len(self._tokens) <= self._idx
endfunction

function! s:obj.next() dict
  if self.end()
    call s:_exception('Already end of tokens.')
  else
    return self._tokens[self._idx]
  endif
endfunction

function! s:obj.next_is(labels) dict
  let labels = type([]) == type(a:labels) ? a:labels : [ a:labels ]
  if ! self.end()
    for lbl in labels
      if self.next().label ==# lbl
        return 1
      endif
    endfor
  endif
  return 0
endfunction

function! s:obj.ignore() dict
  while self.next_is(self._ignore_labels)
    call self.consume()
  endwhile
  return self
endfunction

function! s:obj.consume() dict
  if ! self.end()
    let next = self.next()
    let self._idx += 1
  else
    call s:_exception('Already end of tokens.')
  endif
  return next
endfunction

function! s:obj.tostring() dict
  if ! self.end()
    return ''
  else
    return join( map(deepcopy(self._tokens[(self._idx):]),'v:val.matched_text'), '')
  endif
endfunction

function! s:parser()
  let o = {}
  function! o.exec(lexered_tokens)
    let obj = deepcopy(s:obj)
    let obj._tokens = deepcopy(a:lexered_tokens)
    return obj
  endfunction
  return o
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
