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

Context Vim.Message.capture()
  It returns output string of Vim {command}
    let output = g:M.capture('echo "hi"')
    " Ignore blank lines.
    let keepempty = 0
    let output = join(split(output, '\n', keepempty), '')
    Should output ==# "hi"
  End
End

Context Vim.Message.get_hit_enter_max_length()
  It gets max length of |hit-enter|
    let cmdheight = &cmdheight
    try
        set cmdheight=1
        Should g:M.get_hit_enter_max_length() < &columns * &cmdheight
        set cmdheight=2
        Should g:M.get_hit_enter_max_length() > &columns
        Should g:M.get_hit_enter_max_length() < &columns * &cmdheight
    finally
        let &cmdheight = cmdheight
    endtry
  End
End
