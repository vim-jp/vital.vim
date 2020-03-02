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
    let data = s:TOML.parse_file('./test/_testdata/Text/TOML/toml-sample.txt')

    call s:assert.equals(data, {
    \ 'title': 'TOML Example',
    \ 'owner': {
    \   'name': 'Lance Uppercut',
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
  endfunction

  function! parse.basic_strings()
    let data = s:TOML.parse('hoge="I''m a string. \"You can quote me\". Name\tJos\u0024\nLocation\tSF."')

    call s:assert.same(data.hoge, "I'm a string. \"You can quote me\". Name\tJos\u0024\nLocation\tSF.")
  endfunction

  function! parse.__multiline_basic_strings__()
    let multiline_basic_strings = themis#suite('Multi-line basic strings')

    function! multiline_basic_strings.trims_first_newline()
      let data = s:TOML.parse(join([
      \ 'hoge="""',
      \ 'One',
      \ 'Two"""',
      \], "\n"))

      call s:assert.same(data.hoge, "One\nTwo")
    endfunction

    function! multiline_basic_strings.trims_whitespaces_after_backslash()
      let data = s:TOML.parse(join([
      \ 'hoge= """',
      \ 'The quick brown \',
      \ '',
      \ '',
      \ '  fox jumps over \',
      \ '    the lazy dog."""',
      \], "\n"))

      call s:assert.same(data.hoge, 'The quick brown fox jumps over the lazy dog.')
    endfunction

    function! multiline_basic_strings.trims_whitespaces_after_backslash2()
      let data = s:TOML.parse(join([
      \ 'hoge = """\',
      \ '    The quick brown \',
      \ '    fox jumps over \',
      \ '    the lazy dog.\',
      \ '    """',
      \], "\n"))

      call s:assert.same(data.hoge, 'The quick brown fox jumps over the lazy dog.')
    endfunction

    function! multiline_basic_strings.includes_escaped_character()
      let data = s:TOML.parse(join([
      \ 'hoge = """\',
      \ 'delimiter = ''\"""''\',
      \ '"""',
      \], "\n"))

      call s:assert.same(data.hoge, 'delimiter = ''"""''')
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
    let data = s:TOML.parse(join([
    \ 'regex2 = ''''''I [dw]on''t need \d{2} apples''''''',
    \ 'lines  = ''''''',
    \ 'The first newline is',
    \ 'trimmed in raw strings.',
    \ '   All other whitespace',
    \ '   is preserved.',
    \ '''''''',
    \], "\n"))

    call s:assert.same(data.regex2, 'I [dw]on''t need \d{2} apples')
    call s:assert.same(data.lines,  join([
    \ 'The first newline is',
    \ 'trimmed in raw strings.',
    \ '   All other whitespace',
    \ '   is preserved.',
    \ '',
    \], "\n"))
  endfunction

  function! parse.integer()
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
  endfunction

  function! parse.boolean()
    let data = s:TOML.parse(join([
    \ 'true=true',
    \ 'false=false',
    \], "\n"))

    call s:assert.truthy(data.true)
    call s:assert.falsy(data.false)
  endfunction

  function! parse.datetime()
    let data = s:TOML.parse(join([
    \ 'one=1979-05-27T07:32:00Z',
    \ 'two=1979-05-27T00:32:00-07:00',
    \ 'three=1979-05-27T00:32:00.999999-07:00'
    \], "\n"))

    call s:assert.same(data.one,   '1979-05-27T07:32:00Z')
    call s:assert.same(data.two,   '1979-05-27T00:32:00-07:00')
    call s:assert.same(data.three, '1979-05-27T00:32:00.999999-07:00')
  endfunction

  function! parse.array()
    let data = s:TOML.parse(join([
    \ 'one=[ 1, 2, 3 ]',
    \ 'two=[ "red", "yellow", "green" ]',
    \ 'three=[ [ 1, 2 ], [3, 4, 5] ]',
    \ 'four=[ [ 1, 2 ], ["a", "b", "c"] ] # this is ok',
    \ 'five = [',
    \ '  1, 2, 3',
    \ ']',
    \ 'six = [',
    \ '  1,',
    \ '  2, # this is ok',
    \ ']',
    \], "\n"))

    call s:assert.equals(data.one,   [1, 2, 3])
    call s:assert.equals(data.two,   ['red', 'yellow', 'green'])
    call s:assert.equals(data.three, [[1, 2], [3, 4, 5]])
    call s:assert.equals(data.four,  [[1, 2], ['a', 'b', 'c']])
    call s:assert.equals(data.five,  [1, 2, 3])
    call s:assert.equals(data.six,   [1, 2])
  endfunction

  function! parse.__table__()
    let table = themis#suite('table')

    function! table.simple()
      let data = s:TOML.parse(join([
      \ '[table]',
      \ 'key = "value"',
      \], "\n"))

      call s:assert.equals(data, {
      \ 'table': {
      \   'key': 'value',
      \ },
      \})
    endfunction

    function! table.nested()
      let data = s:TOML.parse(join([
      \ '[ dog . "tater.man" ]',
      \ 'type = "pug"',
      \]))

      call s:assert.equals(data, {
      \ 'dog': {
      \   'tater.man': {
      \     'type': 'pug',
      \   },
      \ },
      \})
    endfunction

    function! table.nested_without_super_tables()
      let data = s:TOML.parse(join([
      \ '# [x] you',
      \ '# [x.y] don''t',
      \ '# [x.y.z] need these',
      \ '[x.y.z.w] # for this to work',
      \], "\n"))

      call s:assert.has_key(data, 'x')
      call s:assert.has_key(data.x, 'y')
      call s:assert.has_key(data.x.y, 'z')
      call s:assert.has_key(data.x.y.z, 'w')
      call s:assert.is_dict(data.x.y.z.w)
      call s:assert.equals(data.x.y.z.w, {})
    endfunction
  endfunction

  function! parse.inline_table()
    let data = s:TOML.parse(join([
    \ '[table.inline]',
    \ '',
    \ 'name = { first = "Tom", last = "Preston-Werner" }',
    \ 'point = { x = 1, y = 2 }'
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
    \       'shape': 'round'
    \     },
    \     'variety': [
    \       { 'name': 'red delicious' },
    \       { 'name': 'granny smith' }
    \     ]
    \   },
    \   {
    \     'name': 'banana',
    \     'variety': [
    \       { 'name': 'plantain' }
    \     ]
    \   }
    \ ]
    \})
  endfunction
endfunction
" vim:set et ts=2 sts=2 sw=2 tw=0:
