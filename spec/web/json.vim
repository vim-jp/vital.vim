source spec/base.vim

let g:J = vital#of('vital').import('Web.JSON')

Context Web.JSON.constants
  It should have constant variables which indicate the special tokens
    Should string(g:J.true) =~ "function('\.*_true')"
    Should string(g:J.false) =~ "function('\.*_false')"
    Should string(g:J.null) =~ "function('\.*_null')"
  End
End


Context Web.JSON.decode()
  It decodes numbers
    Should 0 == g:J.decode(0)
    Should 10 == g:J.decode(10)
    Should 100 == g:J.decode(100)
  End

  It decodes strings
    Should "" == g:J.decode('""')
    Should "a" == g:J.decode('"a"')
    Should "a\rb" == g:J.decode('"a\rb"')
    Should "a\nb" == g:J.decode('"a\nb"')
    Should "a\tb" == g:J.decode('"a\tb"')
    " double quotation
    Should 'He said "I''m a vimmer"' == g:J.decode('"He said \"I''m a vimmer\""')
    " there should be iconv tests as well
  End

  It decodes lists
    Should [] == g:J.decode('[]')
    Should [0,1,2] == g:J.decode('[0, 1, 2]')
    Should ["a","b","c"] == g:J.decode('["a", "b", "c"]')
    " list should be encoded recursively
    Should [[0,1,2],["a","b","c"]] == g:J.decode('[[0,1,2],["a","b","c"]]')
  End

  It decodes dictionaries
    Should {} == g:J.decode('{}')
    Should {"a":0,"b":1,"c":2} == g:J.decode('{"a":0,"b":1,"c":2}')
    Should {'a':'0','b':'1','c':'2'} == g:J.decode('{"a":"0","b":"1","c":"2"}')
    " dictionary should be encoded recursively
    Should {"a":{"b":{"c":[0,1,2]}}} == g:J.decode('{"a":{"b":{"c":[0,1,2]}}}')
  End

  It decodes special tokens (true/false/null)
    " true/false/null
    Should 1 == g:J.decode('true')
    Should 0 == g:J.decode('false')
    Should 0 == g:J.decode('null')

    Should g:J.true == g:J.decode('true', {'use_token': 1})
    Should g:J.false == g:J.decode('false', {'use_token': 1})
    Should g:J.null == g:J.decode('null', {'use_token': 1})
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
    " dictionary should be encoded recursively
    Should '{"a":{"b":{"c":[0,1,2]}}}' == g:J.encode(
          \ {'a': {'b': {'c': [0, 1, 2]}}}
          \)
  End

  " JavaScript special tokens
  It encodes special tokens (true/false/null)
    Should 'true' == g:J.encode(g:J.true)
    Should 'false' == g:J.encode(g:J.false)
    Should 'null' == g:J.encode(g:J.null)
  End
End


" vim:set et ts=2 sts=2 sw=2 tw=0:
