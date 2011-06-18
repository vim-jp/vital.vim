" "Callable thing" in vital.

let s:save_cpo = &cpo
set cpo&vim


" The same arguments as call()
" but first argument is functor.
function! s:call(functor, args, ...)
    if type(a:functor) ==# type("")
    \   || type(a:functor) ==# type(function('tr'))
        return call('call', [a:functor, a:args] + a:000)
    elseif type(a:functor) ==# type({})
    \   && has_key(a:functor, 'do')
        return call(a:functor.do, a:args, a:functor)
    endif
    throw 'vital: Functor.call(): '
    \   . 'a:functor is not callable!'
endfunction


let &cpo = s:save_cpo
