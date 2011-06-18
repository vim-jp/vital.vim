" Utilities about character encoding.

let s:save_cpo = &cpo
set cpo&vim


" NOTE: "s:mb_*()" functions support multibyte.
" But some other functions with no "mb" prefix
" also support multibyte.


" Returns the number of character in a:str.
" s:mb_strlen(str) {{{
if exists('*strchars')
    let s:mb_strlen = function('strchars')
else
    function! s:mb_strlen(str)
        return strlen(substitute(copy(a:str), '.', 'x', 'g'))
    endfunction
endif "}}}

" Remove last character from a:str.
function! s:mb_chop(str) "{{{
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
