scriptencoding utf-8

let s:suite = themis#suite('Text.TOML')
let s:assert = themis#helper('assert')

function! s:suite.before()
  let s:TOML = vital#vital#new().import('Text.TOML')
endfunction

function! s:suite.after()
  unlet! s:TOML
endfunction

function! s:suite.__parse_file__()
  let parse_file = themis#suite('parse_file()')

  function! parse_file.throws_if_file_isnot_readable()
    let toml = s:TOML
    Throw /vital: Text.TOML:/ toml.parse_file('hoge')
  endfunction

  function! parse_file.parses_toml_formatted_file()
    let data = s:TOML.parse_file('./test/_testdata/Text/TOML/sample.toml')

    call s:assert.equals(data, {
    \ 'title': 'TOML Example',
    \ 'owner': {
    \   'name': 'Tom Preston-Werner',
    \   'dob': '1979-05-27T07:32:00-08:00',
    \ },
    \ 'database': {
    \   'server': '192.168.1.1',
    \   'ports': [8001, 8001, 8002],
    \   'connection_max': 5000,
    \   'enabled': 1,
    \ },
    \ 'servers': {
    \   'alpha': {
    \     'ip': '10.0.0.1',
    \     'dc': 'eqdc10',
    \   },
    \   'beta': {
    \     'ip': '10.0.0.2',
    \     'dc': 'eqdc10',
    \   },
    \ },
    \ 'clients': {
    \   'data': [['gamma', 'delta'], [1, 2]],
    \   'hosts': ['alpha', 'omega'],
    \ },
    \ 'products': [
    \   {
    \     'name': 'Hammar',
    \     'sku': 738594937,
    \   },
    \   {},
    \   {
    \     'name': 'Nail',
    \     'sku': 284758393,
    \     'color': 'gray',
    \   },
    \ ],
    \})
  endfunction
endfunction

function! s:suite.__parse__()
  let parse = themis#suite('parse()')

  function! parse.throws_if_input_is_in_illegal_format()
    let toml = s:TOML 
    Throws /vital: Text.TOML:/ toml.parse(']')
  endfunction

  function! parse.__keys__()
    let keys = themis#suite('keys')

    function! keys.bare_keys()
      let data = s:TOML.parse(join([
      \ 'key = "value"',
      \ 'bare_key = "value"',
      \ 'bare-key = "value"',
      \ '1234 = "value"',
      \], "\n"))

      call s:assert.equals(data, {
      \ 'key': 'value',
      \ 'bare_key': 'value',
      \ 'bare-key': 'value',
      \ '1234': 'value',
      \})
    endfunction

    function! keys.quoted_keys()
      let data = s:TOML.parse(join([
      \ '"127.0.0.1" = "value"',
      \ '"character encoding" = "value"',
      \ '"ʎǝʞ" = "value"',
      \ '''key2'' = "value"',
      \ '''quoted "value"'' = "value"',
      \], "\n"))

      call s:assert.equals(data, {
      \ '127.0.0.1': 'value',
      \ 'character encoding': 'value',
      \ 'ʎǝʞ': 'value',
      \ 'key2': 'value',
      \ 'quoted "value"': 'value',
      \})
    endfunction

    function! keys.dotted_keys()
      let data = s:TOML.parse(join([
      \ 'name = "Orange"',
      \ 'physical.color = "orange"',
      \ 'physical.shape = "round"',
      \ 'site."google.com" = true',
      \], "\n"))

      call s:assert.equals(data, {
      \  'name': 'Orange',
      \  'physical': {
      \    'color': 'orange',
      \    'shape': 'round',
      \  },
      \  'site': {
      \    'google.com': 1,
      \  },
      \})
    endfunction

    function! keys.empty_keys()
      let toml = s:TOML
      Throw /vital: Text.TOML:/ toml.parse('= "no key name"')

      call s:assert.equals(s:TOML.parse('"" = "blank"'), {'': 'blank'})
      call s:assert.equals(s:TOML.parse("'' = 'blank'"), {'': 'blank'})
    endfunction
  endfunction

  function! parse.basic_strings()
    let data = s:TOML.parse('str = "I''m a string. \"You can quote me\". Name\tJos\u0024\nLocation\tSF."')

    call s:assert.same(data.str, "I'm a string. \"You can quote me\". Name\tJos\u0024\nLocation\tSF.")
  endfunction

  function! parse.__multiline_basic_strings__()
    let multiline_basic_strings = themis#suite('Multi-line basic strings')

    function! multiline_basic_strings.trims_first_newline()
      for newline in ["\n", "\r\n"]
        let data = s:TOML.parse(join([
        \ 'str1 = """',
        \ 'Roses are red',
        \ 'Violets are blue"""',
        \], newline))

        call s:assert.same(data.str1, join([
        \ 'Roses are red',
        \ 'Violets are blue'
        \], newline))
      endfor
    endfunction

    function! multiline_basic_strings.trims_whitespaces_after_backslash()
      for newline in ["\n", "\r\n"]
        let data = s:TOML.parse(join([
        \ 'str2 = """',
        \ 'The quick brown \',
        \ '',
        \ '',
        \ '  fox jumps over \',
        \ '    the lazy dog."""',
        \ 'str3 = """\',
        \ '    The quick brown \',
        \ '    fox jumps over \',
        \ '    the lazy dog.\',
        \ '    """',
        \], newline))

        call s:assert.same(data.str2, 'The quick brown fox jumps over the lazy dog.')
        call s:assert.same(data.str3, 'The quick brown fox jumps over the lazy dog.')
      endfor
    endfunction

    function! multiline_basic_strings.includes_escaped_character()
      for newline in ["\n", "\r\n"]
        let data = s:TOML.parse(join([
        \ 'str4 = """Here are two quotation marks: "". Simple enough."""',
        \ 'str5 = """Here are three quotation marks: ""\"."""',
        \ 'str6 = """Here are fifteen quotation marks: ""\"""\"""\"""\"""\"."""',
        \ '',
        \ '# "This," she said, "is just a pointless statement."',
        \ 'str7 = """"This," she said, "is just a pointless statement.""""',
        \], newline))

        call s:assert.same(data.str4, 'Here are two quotation marks: "". Simple enough.')
        call s:assert.same(data.str5, 'Here are three quotation marks: """.')
        call s:assert.same(data.str6, 'Here are fifteen quotation marks: """"""""""""""".')
        call s:assert.same(data.str7, '"This," she said, "is just a pointless statement."')
      endfor
    endfunction
  endfunction

  function! parse.literal_string()
    let data = s:TOML.parse(join([
    \ 'winpath  = ''C:\Users\nodejs\templates''',
    \ 'winpath2 = ''\\ServerX\admin$\system32\''',
    \ 'quoted   = ''Tom "Dubs" Preston-Werner''',
    \ 'regex    = ''<\i\c*\s*>''',
    \], "\n"))

    call s:assert.same(data.winpath,  'C:\Users\nodejs\templates')
    call s:assert.same(data.winpath2, '\\ServerX\admin$\system32\')
    call s:assert.same(data.quoted,   'Tom "Dubs" Preston-Werner')
    call s:assert.same(data.regex,    '<\i\c*\s*>')
  endfunction

  function! parse.multiline_literal_string()
    for newline in ["\n", "\r\n"]
      let data = s:TOML.parse(join([
      \ 'regex2 = ''''''I [dw]on''t need \d{2} apples''''''',
      \ 'lines  = ''''''',
      \ 'The first newline is',
      \ 'trimmed in raw strings.',
      \ '   All other whitespace',
      \ '   is preserved.',
      \ '''''''',
      \ '',
      \ 'quot15 = ''''''Here fifteen quotation marks: """""""""""""""''''''',
      \ '',
      \ "# 'That's still pointless', she said.",
      \ "str = ''''That's still pointless', she said.'''",
      \], newline))

      call s:assert.same(data.regex2, 'I [dw]on''t need \d{2} apples')
      call s:assert.same(data.lines,  join([
      \ 'The first newline is',
      \ 'trimmed in raw strings.',
      \ '   All other whitespace',
      \ '   is preserved.',
      \ '',
      \], newline))
      call s:assert.same(data.quot15, 'Here fifteen quotation marks: """""""""""""""')
      call s:assert.same(data.str,    '''That''s still pointless'', she said.')
    endfor
  endfunction

  function! parse.__integer__()
    let integer = themis#suite('integer')

    function! integer.decimal()
      let data = s:TOML.parse(join([
      \ 'int1 = +99',
      \ 'int2 = 42',
      \ 'int3 = 0',
      \ 'int4 = -17',
      \ 'int5 = 1_000',
      \ 'int6 = 5_349_221',
      \ 'int7 = 1_2_3_4_5',
      \], "\n"))

      call s:assert.equals(data.int1, 99)
      call s:assert.equals(data.int2, 42)
      call s:assert.equals(data.int3, 0)
      call s:assert.equals(data.int4, -17)
      call s:assert.equals(data.int5, 1000)
      call s:assert.equals(data.int6, 5349221)
      call s:assert.equals(data.int7, 12345)
    endfunction

    function! integer.binary()
      let data = s:TOML.parse(join([
      \ '# binary with prefix `0b`',
      \ 'bin1 = 0b11010110',
      \ 'bin2 = 0b1101_0110',
      \ 'bin3 = 0b1_1_0_1_0_1_1_0',
      \], "\n"))

      " TODO: workaround for vim-vint<0.4
      call s:assert.equals(data.bin1, +'0b11010110')
      call s:assert.equals(data.bin2, +'0b11010110')
      call s:assert.equals(data.bin3, +'0b11010110')
    endfunction

    function! integer.octal()
      let data = s:TOML.parse(join([
      \ '# octal with prefix `0o`',
      \ 'oct1 = 0o01234567',
      \ 'oct2 = 0o755 # useful for Unix file permissions',
      \ 'oct3 = 0o0_755',
      \ 'oct4 = 0o0_7_5_5',
      \], "\n"))

      call s:assert.equals(data.oct1, 001234567)
      call s:assert.equals(data.oct2, 0755)
      call s:assert.equals(data.oct3, 0755)
      call s:assert.equals(data.oct4, 0755)
    endfunction

    function! integer.hexadecimal()
      let data = s:TOML.parse(join([
      \ '# hexadecimal with prefix `0x`',
      \ 'hex1 = 0xDEADBEEF',
      \ 'hex2 = 0xdeadbeef',
      \ 'hex3 = 0xdead_beef',
      \ 'hex4 = 0xd_e_a_d_b_e_e_f',
      \], "\n"))

      call s:assert.equals(data.hex1, 0xdeadbeef)
      call s:assert.equals(data.hex2, 0xdeadbeef)
      call s:assert.equals(data.hex3, 0xdeadbeef)
      call s:assert.equals(data.hex4, 0xdeadbeef)
    endfunction
  endfunction

  function! parse.__float__()
    let float = themis#suite('float')

    function! float.fractional()
      let data = s:TOML.parse(join([
      \ 'flt1 = +1.0',
      \ 'flt2 = 3.1415',
      \ 'flt3 = -0.01',
      \], "\n"))

      call s:assert.is_float(data.flt1)
      call s:assert.equals(data.flt1, 1.0)

      call s:assert.is_float(data.flt2)
      call s:assert.equals(data.flt2, 3.1415)

      call s:assert.is_float(data.flt3)
      call s:assert.equals(data.flt3, -0.01)
    endfunction

    function! float.exponent()
      let data = s:TOML.parse(join([
      \ 'flt4 = 5e+22',
      \ 'flt5 = 1e6',
      \ 'flt6 = -2E-2',
      \], "\n"))

      call s:assert.is_float(data.flt4)
      call s:assert.equals(data.flt4, 5.0e22)

      call s:assert.is_float(data.flt5)
      call s:assert.equals(data.flt5, 1.0e6)

      call s:assert.is_float(data.flt6)
      call s:assert.equals(data.flt6, -2.0e-2)
    endfunction

    function! float.both()
      let data = s:TOML.parse(join([
      \ 'flt7 = 6.626e-34',
      \], "\n"))

      call s:assert.is_float(data.flt7)
      call s:assert.equals(data.flt7, 6.626e-34)
    endfunction

    function! float.underscores()
      let data = s:TOML.parse(join([
      \ 'flt8 = 224_617.445_991_228',
      \], "\n"))

      call s:assert.is_float(data.flt8)
      call s:assert.equals(data.flt8, 224617.445991228)
    endfunction

    function! float.special_float()
      let data = s:TOML.parse(join([
      \ '# infinity',
      \ 'sf1 = inf  # positive infinity',
      \ 'sf2 = +inf # positive infinity',
      \ 'sf3 = -inf # negative infinity',
      \ '',
      \ '# not a number',
      \ 'sf4 = nan  # actual sNaN/qNan encoding is implementation specific',
      \ 'sf5 = +nan # same as `nan`',
      \ 'sf6 = -nan # valid, actual encoding is implementation specific',
      \], "\n"))

      call s:assert.is_float(data.sf1)
      call s:assert.same(string(data.sf1), 'inf')

      call s:assert.is_float(data.sf2)
      call s:assert.same(string(data.sf2), 'inf')

      call s:assert.is_float(data.sf3)
      call s:assert.same(string(data.sf3), '-inf')

      call s:assert.is_float(data.sf4)
      call s:assert.truthy(isnan(data.sf4))

      call s:assert.is_float(data.sf5)
      call s:assert.truthy(isnan(data.sf5))

      call s:assert.is_float(data.sf6)
      call s:assert.truthy(isnan(data.sf6))
    endfunction
  endfunction

  function! parse.boolean()
    let data = s:TOML.parse(join([
    \ 'bool1 = true',
    \ 'bool2 = false',
    \], "\n"))

    call s:assert.truthy(data.bool1)
    call s:assert.falsy(data.bool2)
  endfunction

  function! parse.offset_datetime()
    let data = s:TOML.parse(join([
    \ 'odt1 = 1979-05-27T07:32:00Z',
    \ 'odt2 = 1979-05-27T00:32:00-07:00',
    \ 'odt3 = 1979-05-27T00:32:00.999999-07:00',
    \ 'odt4 = 1979-05-27 07:32:00Z',
    \], "\n"))

    call s:assert.same(data.odt1, '1979-05-27T07:32:00Z')
    call s:assert.same(data.odt2, '1979-05-27T00:32:00-07:00')
    call s:assert.same(data.odt3, '1979-05-27T00:32:00.999999-07:00')
    call s:assert.same(data.odt4, '1979-05-27 07:32:00Z')
  endfunction

  function! parse.local_datetime()
    let data = s:TOML.parse(join([
    \ 'ldt1 = 1979-05-27T07:32:00',
    \ 'ldt2 = 1979-05-27T00:32:00.999999',
    \], "\n"))

    call s:assert.same(data.ldt1, '1979-05-27T07:32:00')
    call s:assert.same(data.ldt2, '1979-05-27T00:32:00.999999')
  endfunction

  function! parse.local_date()
    let data = s:TOML.parse(join([
    \ 'ld1 = 1979-05-27',
    \], "\n"))

    call s:assert.same(data.ld1, '1979-05-27')
  endfunction

  function! parse.local_time()
    let data = s:TOML.parse(join([
    \ 'lt1 = 07:32:00',
    \ 'lt2 = 00:32:00.999999',
    \], "\n"))

    call s:assert.same(data.lt1, '07:32:00')
    call s:assert.same(data.lt2, '00:32:00.999999')
  endfunction

  function! parse.array()
    let data = s:TOML.parse(join([
    \ 'integers = [ 1, 2, 3 ]',
    \ 'colors = [ "red", "yellow", "green" ]',
    \ 'nested_array_of_int = [ [ 1, 2 ], [3, 4, 5] ]',
    \ 'nested_mixed_array = [ [ 1, 2 ], ["a", "b", "c"] ]',
    \ 'string_array = [ "all", ''strings'', """are the same""", ''''''type'''''' ]',
    \ '',
    \ '# Mixed-type arryas are allowed',
    \ 'numbers = [ 0.1, 0.2, 0.5, 1, 2, 5 ]',
    \ 'contributors = [',
    \ '  "Foo Bar <foo@example.com>"',
    \ '  { name = "Baz Qux", email = "bazqux@example.com", url = "https://example.com/bazqux" }',
    \ ']',
    \ '',
    \ 'integers2 = [',
    \ '  1, 2, 3',
    \ ']',
    \ '',
    \ 'integers3 = [',
    \ '  1,',
    \ '  2, # this is ok',
    \ ']',
    \], "\n"))

    call s:assert.equals(data.integers,            [1, 2, 3])
    call s:assert.equals(data.colors,              ['red', 'yellow', 'green'])
    call s:assert.equals(data.nested_array_of_int, [[1, 2], [3, 4, 5]])
    call s:assert.equals(data.nested_mixed_array,  [[1, 2], ['a', 'b', 'c']])
    call s:assert.equals(data.string_array,        ['all', 'strings', 'are the same', 'type'])
    call s:assert.equals(data.numbers,             [0.1, 0.2, 0.5, 1, 2, 5])
    call s:assert.equals(data.contributors,        ['Foo Bar <foo@example.com>', {'name': 'Baz Qux', 'email': 'bazqux@example.com', 'url': 'https://example.com/bazqux'}])
    call s:assert.equals(data.integers2,           [1, 2, 3])
    call s:assert.equals(data.integers3,           [1, 2])
  endfunction

  function! parse.__table__()
    let table = themis#suite('table')

    function! table.simple()
      let data = s:TOML.parse(join([
      \ '[table-1]',
      \ 'key1 = "some string"',
      \ 'key2 = 123',
      \ '',
      \ '[table-2]',
      \ 'key1 = "another string"',
      \ 'key2 = 456',
      \], "\n"))

      call s:assert.equals(data, {
      \ 'table-1': {
      \   'key1': 'some string',
      \   'key2': 123,
      \ },
      \ 'table-2': {
      \   'key1': 'another string',
      \   'key2': 456,
      \ },
      \})
    endfunction

    function! table.nested()
      let data = s:TOML.parse(join([
      \ '[dog."tater.man"]',
      \ 'type.name = "pug"',
      \]))

      call s:assert.equals(data, {
      \ 'dog': {
      \   'tater.man': {
      \     'type': {
      \       'name': 'pug',
      \     },
      \   },
      \ },
      \})
    endfunction

    function! table.nested_without_super_tables()
      let data = s:TOML.parse(join([
      \ '[a.b.c]           # this is best practice',
      \ '[ d.e.f ]         # same as [d.e.f]',
      \ '[ g . h . i ]     # same as [g.h.i]',
      \ '[ j . "ʞ" . ''l'' ] # same as [j."ʞ".''l'']',
      \ '',
      \ '# [x] you',
      \ '# [x.y] don''t',
      \ '# [x.y.z] need these',
      \ '[x.y.z.w] # for this to work',
      \ '',
      \ '[x] # defining a super-table afterwards is ok',
      \], "\n"))

      call s:assert.has_key(data, 'a')
      call s:assert.equals(data.a, {'b': {'c': {}}})
      call s:assert.has_key(data, 'd')
      call s:assert.equals(data.d, {'e': {'f': {}}})
      call s:assert.has_key(data, 'g')
      call s:assert.equals(data.g, {'h': {'i': {}}})
      call s:assert.has_key(data, 'j')
      call s:assert.equals(data.j, {'ʞ': {'l': {}}})
      call s:assert.has_key(data, 'x')
      call s:assert.equals(data.x, {'y': {'z': {'w': {}}}})
    endfunction
  endfunction

  function! parse.inline_table()
    let data = s:TOML.parse(join([
    \ '[table.inline]',
    \ '',
    \ 'name = { first = "Tom", last = "Preston-Werner" }',
    \ 'point = { x = 1, y = 2 }',
    \ 'animal = { type.name = "pug" }',
    \]))

    call s:assert.equals(data, {
    \ 'table': {
    \   'inline': {
    \     'name': {
    \       'first': 'Tom',
    \       'last': 'Preston-Werner',
    \     },
    \     'point': {
    \       'x': 1,
    \       'y': 2,
    \     },
    \     'animal': {
    \       'type': {
    \         'name': 'pug',
    \       },
    \     },
    \   },
    \ },
    \})
  endfunction

  function! parse.array_of_tables()
    let data = s:TOML.parse(join([
    \ '[[fruit]]',
    \ '  name = "apple"',
    \ '',
    \ '  [fruit.physical]',
    \ '    color = "red"',
    \ '    shape = "round"',
    \ '',
    \ '  [[fruit.variety]]',
    \ '    name = "red delicious"',
    \ '',
    \ '  [[fruit.variety]]',
    \ '    name = "granny smith"',
    \ '',
    \ '[[fruit]]',
    \ '  name = "banana"',
    \ '',
    \ '  [[fruit.variety]]',
    \ '    name = "plantain"',
    \], "\n"))

    call s:assert.equals(data, {
    \ 'fruit': [
    \   {
    \     'name': 'apple',
    \     'physical': {
    \       'color': 'red',
    \       'shape': 'round',
    \     },
    \     'variety': [
    \       { 'name': 'red delicious' },
    \       { 'name': 'granny smith' },
    \     ],
    \   },
    \   {
    \     'name': 'banana',
    \     'variety': [
    \       { 'name': 'plantain' },
    \     ],
    \   },
    \ ],
    \})
  endfunction
endfunction
" vim:set et ts=2 sts=2 sw=2 tw=0:
