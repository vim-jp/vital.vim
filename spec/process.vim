
scriptencoding utf-8
source spec/base.vim

let g:P = vital#of('vital').import('Process')

Context Process.system()
  It runs an external command and returns the stdout
    " assuming you have echo command
    Should g:P.system('echo 1234') ==# "1234\n"
  End
End
