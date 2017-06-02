" Utilities for dictionary.

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Option = s:V.import('Data.Optional')
endfunction

function! s:_vital_depends() abort
  return ['Data.Optional']
endfunction

" Makes a dict from keys and values
function! s:make(keys, values, ...) abort
  let dict = {}
  let fill = a:0 ? a:1 : 0
  for i in range(len(a:keys))
    let key = type(a:keys[i]) == type('') ? a:keys[i] : string(a:keys[i])
    if key ==# ''
      throw "vital: Data.Dict: Can't use an empty string for key."
    endif
    let dict[key] = get(a:values, i, fill)
  endfor
  return dict
endfunction

" Swaps keys and values
function! s:swap(dict) abort
  return s:make(values(a:dict), keys(a:dict))
endfunction

" Makes a index dict from a list
function! s:make_index(list, ...) abort
  let value = a:0 ? a:1 : 1
  return s:make(a:list, [], value)
endfunction

function! s:pick(dict, keys) abort
  let new_dict = {}
  for key in a:keys
    if has_key(a:dict, key)
      let new_dict[key] = a:dict[key]
    endif
  endfor
  return new_dict
endfunction

function! s:omit(dict, keys) abort
  let new_dict = copy(a:dict)
  for key in a:keys
    if has_key(a:dict, key)
      call remove(new_dict, key)
    endif
  endfor
  return new_dict
endfunction

function! s:clear(dict) abort
  for key in keys(a:dict)
    call remove(a:dict, key)
  endfor
  return a:dict
endfunction

function! s:_max_by(dict, expr) abort
  let dict = s:swap(map(copy(a:dict), a:expr))
  let key = dict[max(keys(dict))]
  return [key, a:dict[key]]
endfunction

function! s:max_by(dict, expr) abort
  if empty(a:dict)
    throw 'vital: Data.Dict: Empty dictionary'
  endif
  return s:_max_by(a:dict, a:expr)
endfunction

function! s:min_by(dict, expr) abort
  if empty(a:dict)
    throw 'vital: Data.Dict: Empty dictionary'
  endif
  return s:_max_by(a:dict, '-(' . a:expr . ')')
endfunction

function! s:_foldl(f, init, xs) abort
  let memo = a:init
  for [k, v] in a:xs
    let expr = substitute(a:f, 'v:key', string(k), 'g')
    let expr = substitute(expr, 'v:val', string(v), 'g')
    let expr = substitute(expr, 'v:memo', string(memo), 'g')
    unlet memo
    let memo = eval(expr)
  endfor
  return memo
endfunction

function! s:foldl(f, init, dict) abort
  return s:_foldl(a:f, a:init, items(a:dict))
endfunction

function! s:foldr(f, init, dict) abort
  return s:_foldl(a:f, a:init, reverse(items(a:dict)))
endfunction

function! s:lookup(dict, key) abort
	return has_key(a:dict, a:key)
	\        ? s:Option.some(a:dict[a:key])
	\        : s:Option.none()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
