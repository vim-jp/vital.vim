" Utilities for list.

let s:save_cpo = &cpo
set cpo&vim



" Move a file.
" Dispatch s:move_file_exe() or s:move_file_pure().
function! s:move_file(src, dest, ...) "{{{
    let show_error = a:0 ? a:1 : 1
    if executable('mv')
        return s:move_file_exe(a:src, a:dest, show_error)
    else
        return s:move_file_pure(a:src, a:dest, show_error)
    endif
endfunction "}}}

" Move a file.
" Implemented by 'mv' executable.
function! s:move_file_exe(src, dest, ...)
    if !executable('mv') | return 0 | endif
    silent execute '!mv' shellescape(a:src) shellescape(a:dest)
    if v:shell_error
        if show_error
            call s:warn("'mv' returned failure value: " . v:shell_error)
            sleep 1
        endif
        return 0
    endif
    return 1
endfunction

" Move a file.
" Implemented by pure vimscript.
function! s:move_file_pure(src, dest, ...) "{{{
    let show_error = a:0 ? a:1 : 1
    let copy_success = s:copy_file(a:src, a:dest, show_error)
    let remove_success = delete(a:src) == 0

    if copy_success && remove_success
        return 1
    else
        if show_error
            call s:warn("can't move '" . a:src . "' to '" . a:dest . "'.")
        endif
        return 0
    endif
endfunction "}}}

" Copy a file.
" Dispatch s:copy_file_exe() or s:copy_file_pure().
function! s:copy_file(src, dest, ...) "{{{
    let show_error = a:0 ? a:1 : 1
    if executable('cp')
        return s:copy_file_exe(a:src, a:dest, show_error)
    else
        return s:copy_file_pure(a:src, a:dest, show_error)
    endif
endfunction "}}}

" Copy a file.
" Implemented by 'cp' executable.
function! s:copy_file_exe(src, dest, ...)
    if !executable('cp') | return 0 | endif
    let show_error = a:0 ? a:1 : 1
    silent execute '!cp' shellescape(a:src) shellescape(a:dest)
    if v:shell_error
        if show_error
            call s:warn("'cp' returned failure value: " . v:shell_error)
        endif
        return 0
    endif
    return 1
endfunction

" Copy a file.
" Implemented by pure vimscript.
function! s:copy_file_pure(src, dest, ...) "{{{
    let show_error = a:0 ? a:1 : 1
    let ret = writefile(readfile(a:src, "b"), a:dest, "b")
    if ret == -1
        if show_error
            call s:warn("can't copy '" . a:src . "' to '" . a:dest . "'.")
            sleep 1
        endif
        return 0
    endif
    return 1
endfunction "}}}

" mkdir() but does not throw an exception.
" Returns true if success.
" Returns false if failure.
function! s:mkdir_nothrow(...) "{{{
    try
        call call('mkdir', a:000)
        return 1
    catch
        return 0
    endtry
endfunction "}}}


let &cpo = s:save_cpo
