" "Callable thing" in vital.

let s:save_cpo = &cpo
set cpo&vim


" The same arguments as call()
" but first argument is callable object.
function! s:call(callable, args, ...)
    let functor = s:wrap(a:callable)
    return call(functor.do, a:args, (a:0 ? a:1 : functor))
endfunction

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


let &cpo = s:save_cpo
