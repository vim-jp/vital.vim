source spec/base.vim

let g:J = vital#of('vital').import('Web.JSON')

Context Web.JSON.token()
  It returns corresponding functions
    Should 1 == g:J.token('true')()
    Should 0 == g:J.token('false')()
    Should 0 == g:J.token('null')()
    " there should be 'throw' test but I don't know how to write the test...
  End
End


Context Web.JSON.decode()
  It decode numbers
    Should 0 == g:J.decode(0)
    Should 10 == g:J.decode(10)
    Should 100 == g:J.decode(100)
  End

  It decode strings
    Should "" == g:J.decode('""')
    Should "a" == g:J.decode('"a"')
    Should "a\rb" == g:J.decode('"a\rb"')
    Should "a\nb" == g:J.decode('"a\nb"')
    Should "a\tb" == g:J.decode('"a\tb"')
    " double quotation
    Should 'He said "I''m a vimmer"' == g:J.decode('"He said \"I''m a vimmer\""')
    " true/false/null
    " Note: (by Alisue)
    "   The following behaviors are backward compatble but I think these value
    "   should be distinctive to determine what JSON actually said.
    Should 1 == g:J.decode('true')
    Should 0 == g:J.decode('false')
    Should 0 == g:J.decode('null')
    " there should be iconv tests as well
  End
End


Context Web.JSON.encode()
  It encodes numbers
    Should 0 == g:J.encode(0)
    Should 10 == g:J.encode(10)
    Should 100 == g:J.encode(100)
  End

  It encodes strings
    Should '""' == g:J.encode("")
    Should '"a"' == g:J.encode("a")
    Should '"a\rb"' == g:J.encode("a\rb")
    Should '"a\nb"' == g:J.encode("a\nb")
    Should '"a\tb"' == g:J.encode("a\tb")
    " double quotation should be escaped
    Should '"He said \"I''m a vimmer\""' == g:J.encode('He said "I''m a vimmer"')
    " there should be iconv tests as well
  End

  It encodes lists
    Should '[]' == g:J.encode([])
    Should '[0,1,2]' == g:J.encode([0, 1, 2])
    Should '["a","b","c"]' == g:J.encode(["a", "b", "c"])
    " list should be encoded recursively
    Should '[[0,1,2],["a","b","c"]]' == g:J.encode([
          \ [0, 1, 2],
          \ ["a", "b", "c"],
          \])
  End

  It encodes dictionaries
    Should '{}' == g:J.encode({})
    Should '{"a":0,"b":1,"c":2}' == g:J.encode({'a': 0, 'b': 1, 'c': 2})
    Should '{"a":"0","b":"1","c":"2"}' == g:J.encode({'a': '0', 'b': '1', 'c': '2'})
    " dictionay should be encoded recursively
    Should '{"a":{"b":{"c":[0,1,2]}}}' == g:J.encode(
          \ {'a': {'b': {'c': [0, 1, 2]}}}
          \)
  End

  " JavaScript special tokens
  It encoes special tokens (true/false/null)
    Should 'true' == g:J.encode(g:J.token('true'))
    Should 'false' == g:J.encode(g:J.token('false'))
    Should 'null' == g:J.encode(g:J.token('null'))
  End
End


" vim:set et ts=2 sts=2 sw=2 tw=0:
