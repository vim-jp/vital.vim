let s:save_cpo = &cpo
set cpo&vim


function! s:new(...) abort
  let obj = deepcopy(s:ordered_set)
  if a:0
  \   && type(a:1) == type({})
  \   && has_key(a:1, 'Fn_identifier')
    let obj.Fn_identifier = a:1.Fn_identifier
  endif
  return obj
endfunction


let s:ordered_set = {
\   '_list': [],
\   '_dict': {},
\   '_origin_pos': 0,
\   'Fn_identifier': 'string',
\}

function! s:ordered_set.prepend(list) abort
  for V in reverse(a:list)
    call self.unshift(V)
  endfor
endfunction

function! s:ordered_set.append(list) abort
  for V in a:list
    call self.push(V)
  endfor
endfunction

function! s:ordered_set.push(elem) abort
  let id = call(self.Fn_identifier, [a:elem])
  if !has_key(self._dict, id)
    let self._dict[id] = len(self._list) - self._origin_pos
    call add(self._list, a:elem)
    return 1
  endif
  return 0
endfunction

function! s:ordered_set.unshift(elem) abort
  let id = call(self.Fn_identifier, [a:elem])
  if !has_key(self._dict, id)
    let self._origin_pos += 1
    let self._dict[id] = -self._origin_pos
    call insert(self._list, a:elem)
    return 1
  endif
  return 0
endfunction

function! s:ordered_set.empty() abort
  return empty(self._list)
endfunction

function! s:ordered_set.size() abort
  return len(self._list)
endfunction

function! s:ordered_set.to_list() abort
  return copy(self._list)
endfunction

function! s:ordered_set.has(elem) abort
  let id = call(self.Fn_identifier, [a:elem])
  return has_key(self._dict, id)
endfunction

function! s:ordered_set.has_id(id) abort
  return has_key(self._dict, a:id)
endfunction

function! s:ordered_set.clear() abort
  let self._list = []
  let self._dict  = {}
  let self._origin_pos = 0
endfunction

function! s:ordered_set.remove(elem) abort
  let id = call(self.Fn_identifier, [a:elem])
  if has_key(self._dict, id)
    let idx = self._origin_pos + self._dict[id]
    unlet self._dict[id]
    unlet self._list[idx]
    if idx < self._origin_pos
      for i in range(0, idx - 1)
        let id = call(self.Fn_identifier, [self._list[i]])
        let self._dict[id] += 1
      endfor
      let self._origin_pos -= 1
    else
      for i in range(idx, len(self._list) - 1)
        let id = call(self.Fn_identifier, [self._list[i]])
        let self._dict[id] -= 1
      endfor
    endif
    return 1
  endif
  return 0
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
