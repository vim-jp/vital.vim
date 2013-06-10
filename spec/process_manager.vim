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

" TODO
