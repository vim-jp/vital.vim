source spec/base.vim
scriptencoding utf-8

let g:B = vital#of('vital').import('Interpreter.Brainf__k')

let g:hello_world = "++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>."

Context Brainf__k.run_vim_parse_execute()
  It shows hello world
    redir => output
      silent call g:B.run_vim_parse_execute(g:hello_world)
    redir END
    Should output ==# "Hello World!\n"
  End
End
