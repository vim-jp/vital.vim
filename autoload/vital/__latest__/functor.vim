" "Callable thing" in vital.

let s:save_cpo = &cpo
set cpo&vim


" The same arguments as call()
" but first argument is callable object.
function! s:call(callable, args, ...)
    let functor = s:wrap(a:callable)
    return call(functor.do, a:args, (a:0 ? a:1 : functor))
endfunction

" Wrap
" - function name (String)
" - Funcref value
" - callable object
" with callable object.
function! s:wrap(callable)
    if type(a:callable) ==# type("")
    \   || type(a:callable) ==# type(function('tr'))
        return {'do': function(a:callable)}
    elseif type(a:callable) ==# type({})
    \   && has_key(a:callable, 'do')
        return a:callable
    endif
    throw 'vital: Functor.wrap(): '
    \   . 'a:callable is not callable!'
endfunction

" Bind a:this to a:callable's `self`.
function! s:bind(callable, this)
    let this = copy(a:this)
    let this.do = s:wrap(a:callable).do
    return this
endfunction

let &cpo = s:save_cpo
