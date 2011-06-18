" Utilities about character encoding.

let s:save_cpo = &cpo
set cpo&vim


" Returns the number of character in a:str.
" s:strchars(str) {{{
if exists('*strchars')
    " TODO: Why can't I write like this?
    " let s:strchars = function('strchars')
    function! s:strchars(str)
        return strchars(a:str)
    endfunction
else
    function! s:strchars(str)
        return strlen(substitute(copy(a:str), '.', 'x', 'g'))
    endfunction
endif "}}}

" Remove last character from a:str.
function! s:chop(str) "{{{
    return substitute(a:str, '.$', '', '')
endfunction "}}}

" iconv() wrapper.
" Returns a:expr for error. not empty string.
function! s:iconv(expr, from, to) "{{{
    if a:from == '' || a:to == '' || a:from ==? a:to
        return a:expr
    endif
    let result = iconv(a:expr, a:from, a:to)
    return result != '' ? result : a:expr
endfunction "}}}


let &cpo = s:save_cpo
