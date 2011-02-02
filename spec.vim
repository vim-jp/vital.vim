echo unite#util#truncate('あいうえお', 2) ==# 'あ'
echo unite#util#truncate_smart('this is a pen', 10, 1, '/') ==# 'this is /n'
echo unite#util#truncate_smart('あいうえおかきくけこ.', 10, 1, '/') ==# 'あいうえ/.'
echo unite#util#strchars('this') == 4
echo unite#util#strchars('あいうえお') == 5
echo unite#util#strwidthpart('this is a pen', 5) ==# 'this '
echo unite#util#strwidthpart('あいうえお', 5) ==# 'あい'
echo unite#util#strwidthpart_reverse('this is a pen', 5) ==# 'a pen'
echo unite#util#strwidthpart_reverse('あいうえお', 5) ==# 'えお'
echo unite#util#wcswidth('this is a pen') == 13
echo unite#util#wcswidth('あいうえお') == 10
echo unite#util#is_win() == 0
"call unite#util#print_error('hi')
call unite#util#smart_execute_command('echo', '') " hmm
call unite#util#smart_execute_command('new', '/tmp/supertemp')
if expand('%') =~ '/tmp/supertemp$'
  echo 1
  q!
else
  echoerr 'failed'
endif

