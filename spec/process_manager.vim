source spec/base.vim

let g:V = vital#of('vital')
let g:P = g:V.import('Process')
let g:PM = g:V.import('ProcessManager')

Context ProcessManager.is_available()
  It behaves same to has_vimproc
    Should g:P.has_vimproc() == g:PM.is_available()
  End
End

Context ProcessManager.touch()
  It makes a process synchronously and stores the info inside ProcessManager
    if g:PM.is_available()
      let t = g:PM.touch('aaa', 'cat')
      Should t ==# 'new'
      let t = g:PM.touch('aaa', 'cat')
      Should t ==# 'existing'
    else
      Should "Hey I can't test! install vimproc."
    endif
  End
End


Context ProcessManager.status()
  It is 'stopped' when the process is not working
    call g:PM.touch('spec-status', 'ls') " assuming you have ls command
    sleep " TODO it's evil.
    Should g:PM.status('spec-status') == 'inactive'
  End
  " TODO make new test case about 'active'
End
" TODO
