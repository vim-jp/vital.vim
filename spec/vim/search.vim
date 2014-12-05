source spec/base.vim

let g:S = vital#of('vital').import('Vim.Search')

Context Vim.Search.finddef()
  It returns parsed value
    let result = {}
    try
      new
      let result = g:S.finddef('foo')
    finally
      bw!
    endtry
    Should result == {'1': {}}
  End
  It returns parsed value found
    let result = {}
    try
      new
      call setline(1, ['', '', '', '', 'foo'])
      let result = g:S.finddef('foo')
    finally
      bw!
    endtry
    Should result == {'1': {'6': ' foo'}}
  End
End

" Context Vim.Search.lines()
"   It returns lines separated by CR/LF or LF
"     Should g:S.lines("foobar") == ['foobar']
"     Should g:S.lines("foo\nbar") == ['foo', 'bar']
"     Should g:S.lines("foo\nbar\n") == ['foo', 'bar']
"     Should g:S.lines("\nfoo\nbar\n") == ['foo', 'bar']
"     Should g:S.lines("\nfoo\n\nbar\n") == ['foo', '', 'bar']
"     Should g:S.lines("\n") == []
"     Should g:S.lines("\n\n") == []
"   End
"   " TODO add other specs, refering Bram's Patch 7.3.694
" End
