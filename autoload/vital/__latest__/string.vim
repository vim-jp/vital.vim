" Utilities for string.

let s:save_cpo = &cpo
set cpo&vim

" Substitute a:from => a:to by string.
" To substitute by pattern, use substitute() instead.
function! s:substring(str, from, to)
    if a:str ==# '' || a:from ==# ''
        return a:str
    endif
    let str = a:str
    let idx = stridx(str, a:from)
    while idx !=# -1
        let left  = idx ==# 0 ? '' : str[: idx - 1]
        let right = str[idx + strlen(a:from) :]
        let str = left . a:to . right
        let idx = stridx(str, a:from)
    endwhile
    return str
endfunction

" Substitute a:from => a:to only once.
" cf. s:substring()
function! s:substring_once(str, from, to)
    if a:str ==# '' || a:from ==# ''
        return a:str
    endif
    let idx = stridx(a:str, a:from)
    if idx ==# -1
        return a:str
    else
        let left  = idx ==# 0 ? '' : a:str[: idx - 1]
        let right = a:str[idx + strlen(a:from) :]
        return left . a:to . right
    endif
endfunction


let &cpo = s:save_cpo
