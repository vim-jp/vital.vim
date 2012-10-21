source spec/base.vim

let g:C = vital#of('vital').import('Vim.Compat')

Context Vim.Compat.shiftwidth()
  It gives you &shiftwidth
    Should g:C.shiftwidth() == &shiftwidth
  End
End
