" Utilities for dictionary.

let s:save_cpo = &cpo
set cpo&vim

" Makes a dict from keys and values
function! s:make(keys, values, ...)
  let dict = {}
  let fill = a:0 ? a:1 : 0
  for i in range(len(a:keys))
    let key = type(a:keys[i]) == type('') ? a:keys[i] : string(a:keys[i])
    if key ==# ''
      throw "vital: Data.Dict.make(): Can't use an empty string for key."
    endif
    let dict[key] = get(a:values, i, fill)
  endfor
  return dict
endfunction

" Swaps keys and values
function! s:swap(dict)
  return s:make(values(a:dict), keys(a:dict))
endfunction

" Makes a index dict from a list
function! s:make_index(list, ...)
  let value = a:0 ? a:1 : 1
  return s:make(a:list, [], value)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
