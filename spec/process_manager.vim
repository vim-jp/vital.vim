source spec/base.vim

let g:V = vital#of('vital')
let g:P = g:V.import('ProcessManager')

Context ProcessManager.is_available()
  It behaves same to has_vimproc
    Should g:V.has_vimproc() == g:P.is_available()
  End
End

Context ProcessManager.new()
  It makes a process synchronously ans stores the info inside ProcessManager
    " TODO
  End
End

Context ProcessManager.status()
  It is 'stopped' when the process is not working
    let i = g:P.new('ls') " assuming you have ls command
    sleep " TODO it's evil.
    Should g:P.status(i) == 'stopped'
  End
  " TODO make new test case about 'running'
End
" TODO
