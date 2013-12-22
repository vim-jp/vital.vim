scriptencoding utf-8
source spec/base.vim

let g:V = vital#of('vital')
let g:M = g:V.import('Vim.Message')

Context Vim.Message.error()
  It prints error message
    redir => output
      silent call g:M.error('hi')
    redir END
    " TODO: how to check `echohl ErrorMsg`?
    Should output ==# "\nhi"
  End
End
