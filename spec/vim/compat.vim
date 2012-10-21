source spec/base.vim

let g:C = vital#of('vital').import('Vim.Compat')

Context Vim.Compat.shiftwidth()
  It gives you &shiftwidth
    Should g:C.shiftwidth() == &shiftwidth
  End
  " TODO add other specs, refering Bram's Patch 7.3.694
End
