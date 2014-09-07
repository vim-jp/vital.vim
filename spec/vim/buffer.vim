scriptencoding utf-8
source spec/base.vim

let g:VB = vital#of('vital').import('Vim.Buffer')

Context Vim.Buffer.is_cmdwin()
  It detects if current window is cmdwin.
    " FIXME: CmdWin is closed immediately after it is opened
    " by :normal!, 'cedit'.
    Should !g:VB.is_cmdwin()
    " normal! q:
    " let save_cedit = &cedit
    " let &cedit = "<C-f>"
    " try
    "   execute "normal! :\<C-f>\<CR>"
    "   Should g:VB.is_cmdwin()
    "   quit
    "   Should !g:VB.is_cmdwin()
    " finally
    "   let &cedit = save_cedit
    " endtry
  End
End

Context Vim.Buffer.open()
  It detects if current window is cmdwin.
    " TODO
    Should 1
  End
End

Context Vim.Buffer.get_last_selected()
  It can get the last selected text without textlock error.
    append
foo
bar
baz
.
    normal! ggVGygg
    let text = g:VB.get_last_selected()
    echom string(text)
    Should text ==# "foo\nbar\nbaz\n"
    normal! ggVGy
    Should text ==# @"

    normal! ggvjly
    let text = g:VB.get_last_selected()
    echom string(text)
    Should text ==# "foo\nba"

    execute "normal! gg\<C-v>jly"
    let text = g:VB.get_last_selected()
    echom string(text)
    Should text ==# "fo\nba"

    echom string(getline(1, '$'))
  End

  It does not destroy unnamed register content
    normal! ggVGy
    let @" = "ajapa-"
    call g:VB.get_last_selected()
    Should @" ==# "ajapa-"
  End
End
