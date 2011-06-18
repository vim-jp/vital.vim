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
" NOTE: `s:wrap(callable).do` must be Funcref value.
function! s:wrap(callable)
    if type(a:callable) ==# type("")
        return {'do': function(a:callable)}
    elseif type(a:callable) ==# type(function('tr'))
        return {'do': a:callable}
    elseif type(a:callable) ==# type({})
    \   && has_key(a:callable, 'do')
        if type(a:callable.do) ==# type(function('tr'))
            return a:callable
        elseif type(a:callable.do) ==# type("")
            return extend(a:callable, {
            \   'do': function(a:callable),
            \}, 'force')
        endif
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

" Curry a:callable's 1st argument with a:V.
function! s:curry(callable, V)
    return {
    \   'do': s:localfunc('__curry_stub', s:__sid()),
    \   '__functor': s:wrap(a:callable),
    \   '__value': a:V,
    \}
endfunction
function! s:__curry_stub(...) dict
    return s:call(self.__functor, [self.__value] + a:000)
endfunction
function! s:__sid()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze___sid$')
endfunction

" Convert script-local function to globally callable function.
function! s:localfunc(funcname, sid)
    return printf('<SNR>%d_%s', a:sid, a:funcname)
endfunction


let &cpo = s:save_cpo
