scriptencoding utf-8
source spec/base.vim

let g:V = vital#of('vital')

"Test of wrapper function for type() "{{{
Context Prelude.is_numeric()
  It checks if the argument is a numeric
    Should g:V.is_numeric(3) ==# 1
    Should g:V.is_numeric(3.14159) ==# 1
    Should g:V.is_numeric("") ==# 0
    Should g:V.is_numeric(function('tr')) ==# 0
    Should g:V.is_numeric([]) ==# 0
    Should g:V.is_numeric({}) ==# 0
  End
End

Context Prelude.is_number()
  It checks if the argument is a number
    Should g:V.is_number(3) ==# 1
    Should g:V.is_number(3.14159) ==# 0
    Should g:V.is_number("") ==# 0
    Should g:V.is_number(function('tr')) ==# 0
    Should g:V.is_number([]) ==# 0
    Should g:V.is_number({}) ==# 0
  End
End

Context Prelude.is_float()
  It checks if the argument is a float
    Should g:V.is_float(3) ==# 0
    Should g:V.is_float(3.14159) ==# 1
    Should g:V.is_float("") ==# 0
    Should g:V.is_float(function('tr')) ==# 0
    Should g:V.is_float([]) ==# 0
    Should g:V.is_float({}) ==# 0
  End
End

Context Prelude.is_string()
  It checks if the argument is a string
    Should g:V.is_string(3) ==# 0
    Should g:V.is_string(3.14159) ==# 0
    Should g:V.is_string("") ==# 1
    Should g:V.is_string(function('tr')) ==# 0
    Should g:V.is_string([]) ==# 0
    Should g:V.is_string({}) ==# 0
  End
End

Context Prelude.is_funcref()
  It checks if the argument is a funcref
    Should g:V.is_funcref(3) ==# 0
    Should g:V.is_funcref(3.14159) ==# 0
    Should g:V.is_funcref("") ==# 0
    Should g:V.is_funcref(function('tr')) ==# 1
    Should g:V.is_funcref([]) ==# 0
    Should g:V.is_funcref({}) ==# 0
  End
End

Context Prelude.is_list()
  It checks if the argument is a list
    Should g:V.is_list(3) ==# 0
    Should g:V.is_list(3.14159) ==# 0
    Should g:V.is_list("") ==# 0
    Should g:V.is_list(function('tr')) ==# 0
    Should g:V.is_list([]) ==# 1
    Should g:V.is_list({}) ==# 0
  End
End

Context Prelude.is_dict()
  It checks if the argument is a dictionary
    Should g:V.is_dict(3) ==# 0
    Should g:V.is_dict(3.14159) ==# 0
    Should g:V.is_dict("") ==# 0
    Should g:V.is_dict(function('tr')) ==# 0
    Should g:V.is_dict([]) ==# 0
    Should g:V.is_dict({}) ==# 1
  End
End
"}}}

Context Prelude.truncate()
  It truncates not based on the number of letters but based on visual length
    Should g:V.truncate('あいうえお', 2) ==# 'あ'
  End
End

Context Prelude.truncate_skipping()
  It truncates similarly to Prelude.truncate() but shows a given letter in snip area
    Should g:V.truncate_skipping('this is a pen', 10, 1, '/') ==# 'this is /n'
    Should g:V.truncate_skipping('あいうえおかきくけこ.', 10, 1, '/') ==# 'あいうえ/.'
  End
End

Context Prelude.truncate_smart()
  It truncates similarly to Prelude.truncate() but shows a given letter in snip area
    Should g:V.truncate_smart('this is a pen', 10, 1, '/') ==# 'this is /n'
    Should g:V.truncate_smart('あいうえおかきくけこ.', 10, 1, '/') ==# 'あいうえ/.'
  End
End

Context Prelude.strwidthpart()
  It cuts a string to give width
    Should g:V.strwidthpart('this is a pen', 5) ==# 'this '
    Should g:V.strwidthpart('あいうえお', 5) ==# 'あい'
  End
  It returns an empty string by illegal width
    Should g:V.strwidthpart('あいうえお', -1) ==# ''
  End
End

Context Prelude.strwidthpart_reverse()
  It cuts backward a string to give width
    Should g:V.strwidthpart_reverse('this is a pen', 5) ==# 'a pen'
    Should g:V.strwidthpart_reverse('あいうえお', 5) ==# 'えお'
  End
  It returns an empty string by illegal width
    Should g:V.strwidthpart_reverse('あいうえお', -1) ==# ''
  End
End

  "IS unite#util#wcswidth('this is a pen'), 13
  "IS unite#util#wcswidth('あいうえお'), 10
  "IS unite#util#is_win(), 0

Context Prelude.print_error()
  It prints error message
    redir => output
      silent call g:V.print_error('hi')
    redir END
    " TODO: how to check `echohl ErrorMsg`?
    Should output ==# "\nhi"
  End
End

  "call unite#util#smart_execute_command('echo', '') " hmm

  "let tempname = tempname()
  "call unite#util#smart_execute_command('new', tempname)
  "IS expand('%'), tempname

  "redraw
  "echohl Underlined
  "echom 'Test done.'
  "echohl None
  "sleep 1

Context Prelude.system()
  It runs an external command and returns the stdout
    " assuming you have echo command
    Should g:V.system('echo 1234') ==# "1234\n"
  End
End


Context Prelude.is_cygwin()
  It is true only when the platform is cygwin
    Should g:V.is_cygwin() ==# has('win32unix')
  End
End

Context Prelude.is_windows()
  It is true only when the platform is MS Windows
    Should g:V.is_windows() ==# has('win16') || has('win32') || has('win64')
  End
End

Context Prelude.is_mac()
  It is true only when the platform is Mac OS X
    Should g:V.is_mac() ==# (!g:V.is_windows() && !g:V.is_cygwin() && (has('mac') || has('macunix') || has('gui_macvim') || (!isdirectory('/proc') && executable('sw_vers'))))
  End
End
