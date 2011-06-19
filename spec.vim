command!
\   -nargs=+
\   OK
\   call s:ok([<args>])
function! s:ok(args)
    if len(a:args) !=# 1
        echom '[:OK] Arguments are not 1 length: '.string(a:args)
        return
    endif
    if !a:args[0]
        echom <q-args>." ... FAIL"
    endif
endfunction

" Assumption: No side-effect for arg 1 and 2.
command!
\   -nargs=+
\   IS
\   call s:is([<args>])
function! s:is(args)
    if len(a:args) !=# 2
        echom '[:IS] Arguments are not 2 length: '.string(a:args)
        return
    endif
    if a:args[0] !=# a:args[1]
        echom join(a:args, " ==# ")." ... FAIL"
    endif
endfunction

IS unite#util#truncate('あいうえお', 2), 'あ'
IS unite#util#truncate_smart('this is a pen', 10, 1, '/'), 'this is /n'
IS unite#util#truncate_smart('あいうえおかきくけこ.', 10, 1, '/'), 'あいうえ/.'
IS unite#util#strchars('this'), 4
IS unite#util#strchars('あいうえお'), 5
IS unite#util#strwidthpart('this is a pen', 5), 'this '
IS unite#util#strwidthpart('あいうえお', 5), 'あい'
IS unite#util#strwidthpart_reverse('this is a pen', 5), 'a pen'
IS unite#util#strwidthpart_reverse('あいうえお', 5), 'えお'
IS unite#util#wcswidth('this is a pen'), 13
IS unite#util#wcswidth('あいうえお'), 10
IS unite#util#is_win(), 0

" TODO: May I use :redir to test output?
"call unite#util#print_error('hi')
call unite#util#smart_execute_command('echo', '') " hmm

let tempname = tempname()
call unite#util#smart_execute_command('new', tempname)
IS expand('%'), tempname

redraw
echohl Underlined
echom 'Test done.'
echohl None
sleep 1
