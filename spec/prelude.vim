source spec/base.vim

let g:V = vital#of('vital')

Context Prelude.truncate()
  It truncates not based on the number of letters but based on visual length
    Should g:V.truncate('あいうえお', 2) ==# 'あ'
  End
End

Context Prelude.truncate_smart()
  It truncates similarly to Prelude.truncate() but shows a given letter in snip area
    Should g:V.truncate_smart('this is a pen', 10, 1, '/') ==# 'this is /n'
    Should g:V.truncate_smart('あいうえおかきくけこ.', 10, 1, '/') ==# 'あいうえ/.'
  End
End

  "IS unite#util#strchars('this'), 4
  "IS unite#util#strchars('あいうえお'), 5
  "IS unite#util#strwidthpart('this is a pen', 5), 'this '
  "IS unite#util#strwidthpart('あいうえお', 5), 'あい'
  "IS unite#util#strwidthpart_reverse('this is a pen', 5), 'a pen'
  "IS unite#util#strwidthpart_reverse('あいうえお', 5), 'えお'
  "IS unite#util#wcswidth('this is a pen'), 13
  "IS unite#util#wcswidth('あいうえお'), 10
  "IS unite#util#is_win(), 0

  "" TODO: May I use :redir to test output?
  ""call unite#util#print_error('hi')
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
