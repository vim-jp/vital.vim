" "Callable thing" in vital.

let s:save_cpo = &cpo
set cpo&vim


" The same arguments as call()
" but first argument is callable object.
function! s:call(functor, args, ...)
    let functor = s:wrap(a:functor)
    return call(functor.do, a:args, functor)
endfunction

function! s:wrap(functor)
    if type(a:functor) ==# type("")
    \   || type(a:functor) ==# type(function('tr'))
        return {'do': function(a:functor)}
    elseif type(a:functor) ==# type({})
    \   && has_key(a:functor, 'do')
        return a:functor
    endif
    throw 'vital: Functor.wrap(): '
    \   . 'a:functor is not callable!'
endfunction


let &cpo = s:save_cpo
