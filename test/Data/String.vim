
scriptencoding utf-8

let s:suite = themis#suite('Data.String')
let s:assert = themis#helper('assert')

function! s:suite.before()
  let s:String = vital#vital#new().import('Data.String')
endfunction

function! s:suite.after()
  unlet! s:String
endfunction

function! s:suite.trim()
  call s:assert.equals(s:String.trim('hello'), 'hello')
  call s:assert.equals(s:String.trim('hello '), 'hello')
  call s:assert.equals(s:String.trim(' hello'), 'hello')
  call s:assert.equals(s:String.trim(' hello '), 'hello')
  call s:assert.equals(s:String.trim('hello   '), 'hello')
  call s:assert.equals(s:String.trim('   hello'), 'hello')
  call s:assert.equals(s:String.trim('   hello  world !     '), 'hello  world !')
  call s:assert.equals(s:String.trim(''), '')
  call s:assert.equals(s:String.trim('  '), '')
  call s:assert.equals(s:String.trim(" \t\r\n\x0b\x0c"), '')
  call s:assert.equals(s:String.trim(" \t\r\n\x0b\x0chello \t\r\n\x0b\x0c"), 'hello')
  call s:assert.equals(s:String.trim(" \t\r\n\x0b\x0chello"), 'hello')
  call s:assert.equals(s:String.trim("hello \t\r\n\x0b\x0c"), 'hello')
  " trim() trims control characters between 0x0a-0x0d including LF, CR
  for n in range(0x0a, 0x0d)
    let c = nr2char(n)
    call s:assert.equals(s:String.trim(c . 'hello' . c), 'hello', printf('trim 0x%02x (without SPC(0x20))', n))
    call s:assert.equals(s:String.trim(c . '  hello  ' . c), 'hello', printf('trim 0x%02x (with SPC(0x20))', n))
  endfor
endfunction

function! s:suite.trim_start()
  call s:assert.equals(s:String.trim_start('hello'), 'hello')
  call s:assert.equals(s:String.trim_start('hello '), 'hello ')
  call s:assert.equals(s:String.trim_start(' hello'), 'hello')
  call s:assert.equals(s:String.trim_start(' hello '), 'hello ')
  call s:assert.equals(s:String.trim_start('hello   '), 'hello   ')
  call s:assert.equals(s:String.trim_start('   hello'), 'hello')
  call s:assert.equals(s:String.trim_start('   hello  world !     '), 'hello  world !     ')
  call s:assert.equals(s:String.trim_start(''), '')
  call s:assert.equals(s:String.trim_start('  '), '')
  call s:assert.equals(s:String.trim_start(" \t\r\n\x0b\x0c"), '')
  call s:assert.equals(s:String.trim_start(" \t\r\n\x0b\x0chello \t\r\n\x0b\x0c"), "hello \t\r\n\x0b\x0c")
  call s:assert.equals(s:String.trim_start(" \t\r\n\x0b\x0chello"), 'hello')
  call s:assert.equals(s:String.trim_start("hello \t\r\n\x0b\x0c"), "hello \t\r\n\x0b\x0c")
  " trim_start() trims control characters between 0x0a-0x0d including LF, CR
  for n in range(0x0a, 0x0d)
    let c = nr2char(n)
    call s:assert.equals(s:String.trim_start(c . 'hello' . c), 'hello' . c, printf('trim_start 0x%02x (without SPC(0x20))', n))
    call s:assert.equals(s:String.trim_start(c . '  hello  ' . c), 'hello  ' . c, printf('trim_start 0x%02x (with SPC(0x20))', n))
  endfor
endfunction

function! s:suite.trim_end()
  call s:assert.equals(s:String.trim_end('hello'), 'hello')
  call s:assert.equals(s:String.trim_end('hello '), 'hello')
  call s:assert.equals(s:String.trim_end(' hello'), ' hello')
  call s:assert.equals(s:String.trim_end(' hello '), ' hello')
  call s:assert.equals(s:String.trim_end('hello   '), 'hello')
  call s:assert.equals(s:String.trim_end('   hello'), '   hello')
  call s:assert.equals(s:String.trim_end('   hello  world !     '), '   hello  world !')
  call s:assert.equals(s:String.trim_end(''), '')
  call s:assert.equals(s:String.trim_end('  '), '')
  call s:assert.equals(s:String.trim_end(" \t\r\n\x0b\x0c"), '')
  call s:assert.equals(s:String.trim_end(" \t\r\n\x0b\x0chello \t\r\n\x0b\x0c"), " \t\r\n\x0b\x0chello")
  call s:assert.equals(s:String.trim_end(" \t\r\n\x0b\x0chello"), " \t\r\n\x0b\x0chello")
  call s:assert.equals(s:String.trim_end("hello \t\r\n\x0b\x0c"), 'hello')
  " trim_end() trims control characters between 0x0a-0x0d including LF, CR
  for n in range(0x0a, 0x0d)
    let c = nr2char(n)
    call s:assert.equals(s:String.trim_end(c . 'hello' . c), c . 'hello', printf('trim_end 0x%02x (without SPC(0x20))', n))
    call s:assert.equals(s:String.trim_end(c . '  hello  ' . c), c . '  hello', printf('trim_end 0x%02x (with SPC(0x20))', n))
  endfor
endfunction

function! s:suite.wrap()
  " makes a list from the given string, considering linebreak and width like wrap option
  call s:assert.equals( ['a', 'hello, world!'], s:String.wrap("a\nhello, world!"))
  call s:assert.equals( ['a', 'hello, world!'], s:String.wrap("a\r\nhello, world!"))
  call s:assert.equals( ['a', 'hello, world!'], s:String.wrap("a\rhello, world!"))
  let [&columns, columns] = [12, &columns]
  call s:assert.equals( ['a', 'hello, worl', 'd!'], s:String.wrap("a\nhello, world!"))
  let &columns = columns
endfunction

function! s:suite.replace()
  " substitutes arg2 to arg3 from arg1
  " TODO: Write common tests in one place
  " Common tests for replace(), replace_first()
  call s:assert.equals( s:String.replace('foobar', 'ob', ''), 'foar')
  call s:assert.equals( s:String.replace('foobar', 'foo', ''), 'bar')
  call s:assert.equals( s:String.replace('foobar', 'ar', ''), 'foob')
  call s:assert.equals( s:String.replace('', 'foo', ''), '')
  call s:assert.equals( s:String.replace('foobar', '', ''), 'foobar')
  call s:assert.equals( s:String.replace('foobar', 'bar', 'barbaz'), 'foobarbaz')
  call s:assert.equals( s:String.replace('foobar', 'bar', 'baz'), 'foobaz')

  " Specific tests for Data.String.replace()
  call s:assert.equals( s:String.replace('hello', 'l', ''), 'heo')
  call s:assert.equals( s:String.replace('hello', 'l', 'L'), 'heLLo')
  call s:assert.equals( s:String.replace('hello', 'l', 'LL'), 'heLLLLo')
  call s:assert.equals( s:String.replace('queue', 'ue', ''), 'q')
  call s:assert.equals( s:String.replace('queue', 'ue', 'u'), 'quu')
  call s:assert.equals( s:String.replace('queue', 'ue', 'uu'), 'quuuu')
  call s:assert.equals( s:String.replace('mimic', 'mi', ''), 'c')
  call s:assert.equals( s:String.replace('mimic', 'mi', 'm'), 'mmc')
  call s:assert.equals( s:String.replace('mimic', 'mi', 'mm'), 'mmmmc')
  call s:assert.equals( s:String.replace('\(.*\)', '.', ''), '\(*\)')
  call s:assert.equals( s:String.replace('\v.\m.\M.', '.', ''), '\v\m\M')
  call s:assert.equals( s:String.replace('\v.\m.\M.', '\', ''), 'v.m.M.')
  call s:assert.equals( s:String.replace('\(.*\)', '.', '\0'), '\(\0*\)')
  call s:assert.equals( s:String.replace('\(.*\)', '.', '\=submatch(1)'), '\(\=submatch(1)*\)')
endfunction

function! s:suite.replace_first()
  " is like Data.String.replace(), but this substitutes the first matching substring, not all
  " TODO: Write common tests in one place
  " Common tests for replace(), replace_first()
  call s:assert.equals( s:String.replace_first('foobar', 'ob', ''), 'foar')
  call s:assert.equals( s:String.replace_first('foobar', 'foo', ''), 'bar')
  call s:assert.equals( s:String.replace_first('foobar', 'ar', ''), 'foob')
  call s:assert.equals( s:String.replace_first('', 'foo', ''), '')
  call s:assert.equals( s:String.replace_first('foobar', '', ''), 'foobar')
  call s:assert.equals( s:String.replace_first('foobar', 'bar', 'barbaz'), 'foobarbaz')
  call s:assert.equals( s:String.replace_first('foobar', 'bar', 'baz'), 'foobaz')

  " Specific tests for Data.String.replace_first()
  call s:assert.equals( s:String.replace_first('hello', 'l', ''), 'helo')
  call s:assert.equals( s:String.replace_first('hello', 'l', 'L'), 'heLlo')
  call s:assert.equals( s:String.replace_first('hello', 'l', 'LL'), 'heLLlo')
  call s:assert.equals( s:String.replace_first('queue', 'ue', ''), 'que')
  call s:assert.equals( s:String.replace_first('queue', 'ue', 'u'), 'quue')
  call s:assert.equals( s:String.replace_first('queue', 'ue', 'uu'), 'quuue')
  call s:assert.equals( s:String.replace_first('mimic', 'mi', ''), 'mic')
  call s:assert.equals( s:String.replace_first('mimic', 'mi', 'm'), 'mmic')
  call s:assert.equals( s:String.replace_first('mimic', 'mi', 'mm'), 'mmmic')
  call s:assert.equals( s:String.replace_first('\(.*\)', '.', ''), '\(*\)')
  call s:assert.equals( s:String.replace_first('\v.\m.\M.', '.', ''), '\v\m.\M.')
  call s:assert.equals( s:String.replace_first('\v.\m.\M.', '\', ''), 'v.\m.\M.')
  call s:assert.equals( s:String.replace_first('\(.*\)', '.', '\0'), '\(\0*\)')
  call s:assert.equals( s:String.replace_first('\(.*\)', '.', '\=submatch(1)'), '\(\=submatch(1)*\)')
endfunction

function! s:suite.scan()
  " scans a string by a pattern and returns a list of matched strings
  call s:assert.equals( s:String.scan('neo compl cache', 'c\w\+'), ['compl', 'cache'])
  call s:assert.equals( s:String.scan('[](){}', '[{()}]'), ['(', ')', '{', '}'])
  call s:assert.equals( s:String.scan('string', '.*'), ['string'])
  call s:assert.equals( s:String.scan('string', '.\zs'), ['', '', '', '', '', ''])
  call s:assert.equals( s:String.scan('string', ''), ['', '', '', '', '', '', ''])
endfunction

function! s:suite.reverse()
  " returns a reversed string
  call s:assert.equals( s:String.reverse('string'), 'gnirts')
  call s:assert.equals( s:String.reverse(''), '')
  " works on character base
  call s:assert.equals( s:String.reverse('あいうえお'), 'おえういあ')
endfunction

function! s:suite.starts_with() abort
  call s:assert.true( s:String.starts_with('vital.vim', 'vi'))
  call s:assert.false( s:String.starts_with('vital.vim', 'vim'))
endfunction

function! s:suite.ends_with() abort
  call s:assert.true( s:String.ends_with('vital.vim', 'vim'))
  call s:assert.false( s:String.ends_with('vital.vim', 'vi'))
  call s:assert.false( s:String.ends_with('vital.vim', 'hogefoobar'))
endfunction

function! s:suite.common_head()
  " returns common part of head of strings
  call s:assert.equals( s:String.common_head(['neocomplcache', 'neosnippet', 'neobundle']), 'neo')
  call s:assert.equals( s:String.common_head(['neocomplcache', 'vimshell']), '')
  " returns an empty string if empty string in list
  call s:assert.equals( s:String.common_head(['neocomplcache', '']), '')
  call s:assert.equals( s:String.common_head(['', 'neocomplcache']), '')
  call s:assert.equals( s:String.common_head(['', '']), '')
  call s:assert.equals( s:String.common_head(['']), '')

  " is case-sensitive
  set ignorecase
  call s:assert.equals( s:String.common_head(['call', 'Completion', 'common']), '')
  call s:assert.equals( s:String.common_head(['HEAD', 'Hear']), 'H')
  set ignorecase&

  " returns an empty string with empty list
  call s:assert.equals( s:String.common_head([]), '')
  " is safe for regexp characters
  call s:assert.equals( s:String.common_head(['^o^', '^oo^']), '^o')
  call s:assert.equals( s:String.common_head(['\', '\']), '\')
  call s:assert.equals( s:String.common_head(['*_*', '*_*']), '*_*')
  call s:assert.equals( s:String.common_head(['...-..--', '...-..--']), '...-..--')
  call s:assert.equals( s:String.common_head(['[', '[']), '[')
  call s:assert.equals( s:String.common_head([']', ']']), ']')
endfunction

function! s:suite.split3()
  " splits into two substrings: left/right substring next to matched string with pattern
  call s:assert.equals( s:String.split3('neocomplcache', 'compl'), ['neo', 'compl', 'cache'])
  call s:assert.equals( s:String.split3('autocomplpop', 'compl'), ['auto', 'compl', 'pop'])
  call s:assert.equals( s:String.split3('neocomplcache', 'neo'), ['', 'neo', 'complcache'])
  call s:assert.equals( s:String.split3('autocomplpop', 'auto'), ['', 'auto', 'complpop'])
  call s:assert.equals( s:String.split3('neocomplcache', 'cache'), ['neocompl', 'cache', ''])
  call s:assert.equals( s:String.split3('autocomplpop', 'pop'), ['autocompl', 'pop', ''])
  " Invalid arguments
  call s:assert.equals( s:String.split3('', 'compl'), ['', '', ''])
  call s:assert.equals( s:String.split3('neo', ''), ['', '', ''])
  call s:assert.equals( s:String.split3('', ''), ['', '', ''])
  " No match
  call s:assert.equals( s:String.split3('neocomplcache', 'neocon'), ['', '', ''])
  call s:assert.equals( s:String.split3('neocomplcache', 'neco'), ['', '', ''])
  " Pattern
  call s:assert.equals( s:String.split3('neocomplcache', '...\zs.....'), ['neo', 'compl', 'cache'])
  call s:assert.equals( s:String.split3('neocomplcache', '.\zs..\ze.....'), ['n', 'eo', 'complcache'])
  call s:assert.equals( s:String.split3('neocomplcache', '........'), ['', 'neocompl', 'cache'])
  call s:assert.equals( s:String.split3('neocomplcache', '........\zs....\ze.'), ['neocompl', 'cach', 'e'])
  call s:assert.equals( s:String.split3('neocomplcache', 'neo\zscompl.....'), ['neo', 'complcache', ''])
endfunction

function! s:suite.split_leftright()
  " splits into two substrings: left/right substring next to matched string with pattern
  call s:assert.equals( s:String.split_leftright('neocomplcache', 'compl'), ['neo', 'cache'])
  call s:assert.equals( s:String.split_leftright('autocomplpop', 'compl'), ['auto', 'pop'])
  call s:assert.equals( s:String.split_leftright('neocomplcache', 'neo'), ['', 'complcache'])
  call s:assert.equals( s:String.split_leftright('autocomplpop', 'auto'), ['', 'complpop'])
  call s:assert.equals( s:String.split_leftright('neocomplcache', 'cache'), ['neocompl', ''])
  call s:assert.equals( s:String.split_leftright('autocomplpop', 'pop'), ['autocompl', ''])
  " Invalid arguments
  call s:assert.equals( s:String.split_leftright('', 'compl'), ['', ''])
  call s:assert.equals( s:String.split_leftright('neo', ''), ['', ''])
  call s:assert.equals( s:String.split_leftright('', ''), ['', ''])
  " No match
  call s:assert.equals( s:String.split_leftright('neocomplcache', 'neocon'), ['', ''])
  call s:assert.equals( s:String.split_leftright('neocomplcache', 'neco'), ['', ''])
  " Pattern
  call s:assert.equals( s:String.split_leftright('neocomplcache', '...\zs.....'), ['neo', 'cache'])
  call s:assert.equals( s:String.split_leftright('neocomplcache', '.\zs..\ze.....'), ['n', 'complcache'])
  call s:assert.equals( s:String.split_leftright('neocomplcache', '........'), ['', 'cache'])
  call s:assert.equals( s:String.split_leftright('neocomplcache', '........\zs....\ze.'), ['neocompl', 'e'])
  call s:assert.equals( s:String.split_leftright('neocomplcache', 'neo\zscompl.....'), ['neo', ''])
endfunction

function! s:suite.strchars()
  " returns the number of character, not byte
  call s:assert.equals( s:String.strchars('this'), 4)
  call s:assert.equals( s:String.strchars('あいうえお'), 5)
  call s:assert.equals( s:String.strchars('aiueo'), 5)
  call s:assert.equals( s:String.strchars(''), 0)
  call s:assert.equals( s:String.strchars('あiうeお'), 5)
  call s:assert.equals( s:String.strchars('aいuえo'), 5)
  if &ambiwidth ==# 'single'
    call s:assert.equals( s:String.strchars('Shougo△'), 7)
  elseif &ambiwidth ==# 'double'
    call s:assert.equals( s:String.strchars('Shougo△'), 8)
  elseif &ambiwidth ==# 'auto'
    " TODO: I don't know +kaoriya version's "auto" behavior...
  else
    " wtf?
    let be_nonsense = 0
    Should be_nonsense
  endif
endfunction

function! s:suite.nsplit()
  " splits into strings determines number with pattern
  call s:assert.equals( s:String.nsplit('neo compl_cache', 2, '[ _]'), ['neo', 'compl_cache'])
  call s:assert.equals( s:String.nsplit('neo compl_cache', 3, '[ _]'), ['neo', 'compl', 'cache'])
  call s:assert.equals( s:String.nsplit('neo compl__cache', 2, '[ _]'), ['neo', 'compl__cache'])
  call s:assert.equals( s:String.nsplit('neo compl__cache', 3, '[ _]'), ['neo', 'compl', '_cache'])
  call s:assert.equals( s:String.nsplit('neo compl__cache', 4, '[ _]'), ['neo', 'compl', '', 'cache'])
  call s:assert.equals( s:String.nsplit('neo compl__cache', 2, '[ _]', 0), ['neo', 'compl__cache'])
  call s:assert.equals( s:String.nsplit('neo compl__cache', 3, '[ _]', 0), ['neo', 'compl', '_cache'])
  call s:assert.equals( s:String.nsplit('neo compl__cache', 4, '[ _]', 0), ['neo', 'compl', 'cache'])
  call s:assert.equals( s:String.nsplit('bar::', 1, ':', 1), ['bar::'])
  call s:assert.equals( s:String.nsplit('bar::', 2, ':', 1), ['bar', ':'])
  call s:assert.equals( s:String.nsplit('bar::', 3, ':', 1), ['bar', '', ''])
  call s:assert.equals( s:String.nsplit('bar::', 4, ':', 1), ['bar', '', ''])
endfunction

function! s:suite.diffidx()
  " returns the index of string that found a different
  call s:assert.equals( s:String.diffidx('abcde', 'abdce'), 2)
  call s:assert.equals( s:String.diffidx('', ''), -1)
  call s:assert.equals( s:String.diffidx('', 'a'), 0)
  call s:assert.equals( s:String.diffidx('a', ''), 0)
  call s:assert.equals( s:String.diffidx('a', 'ab'), 1)
  call s:assert.equals( s:String.diffidx('a', 'a'), -1)
  call s:assert.equals( s:String.diffidx('▽', '▼'), 0)
endfunction

function! s:suite.substitute_last()
  " makes new string substituting a given string with the given regexp pattern, but only the last matched part.
  call s:assert.equals( s:String.substitute_last('vital is vim', 'i', 'ooo'), 'vital is vooom')
endfunction

function! s:suite.dstring()
  " wraps the result string not with single-quotes but with double-quotes.
  call s:assert.equals( s:String.dstring(123), '"123"')
  call s:assert.equals( s:String.dstring('abc'), '"abc"')
endfunction

function! s:suite.lines()
  " splits into list of strings of each lines of {str}.
  call s:assert.equals( s:String.lines("a\nb\r\nc"), ['a', 'b', 'c'])
endfunction

function! s:suite.contains_multibyte()
  " returns 1 if the string contains multibyte
  call s:assert.equals( s:String.contains_multibyte('あ'), 1)
  call s:assert.equals( s:String.contains_multibyte('a'), 0)
  call s:assert.equals( s:String.contains_multibyte('aあ'), 1)
  call s:assert.equals( s:String.contains_multibyte('aあa'), 1)
  call s:assert.equals( s:String.contains_multibyte(''), 0)
endfunction

function! s:suite.pad_left()
  " returns a string padded left side until given width with the given half-width character or white-space, considering non-half-width characters.
  call s:assert.equals( s:String.pad_left('test', 11)       , '       test')
  call s:assert.equals( s:String.pad_left('テスト', 11)     , '     テスト')
  call s:assert.equals( s:String.pad_left('テスト', 11, '-'), '-----テスト')
  " Can't use non-half-width characters for padding.
  try
    call s:String.pad_left('test', 11, '＋')
    call s:assert.fail('pad_left')
  catch
  endtry
endfunction

function! s:suite.pad_right()
  " returns a string padded right side until given width with the given half-width character or white-space, considering non-half-width characters.
  call s:assert.equals( s:String.pad_right('test', 11)       , 'test       ')
  call s:assert.equals( s:String.pad_right('テスト', 11)     , 'テスト     ')
  call s:assert.equals( s:String.pad_right('テスト', 11, '-'), 'テスト-----')
  " Can't use non-half-width characters for padding.
  try
    call s:String.pad_right('test', 11, '＋')
    call s:assert.fail('pad_right')
  catch
  endtry
endfunction

function! s:suite.pad_both_sides()
  " returns a string padded left and right side until given width with the given half-width character or white-space, considering non-half-width characters.
  call s:assert.equals( s:String.pad_both_sides('test', 11)       , '   test    ')
  call s:assert.equals( s:String.pad_both_sides('テスト', 11)     , '  テスト   ')
  call s:assert.equals( s:String.pad_both_sides('テスト', 11, '-'), '--テスト---')
  " Can't use non-half-width characters for padding.
  try
    call s:String.pad_both_sides('test', 11, '＋')
    call s:assert.fail('pad_both_sides')
  catch
  endtry
endfunction

function! s:suite.pad_between_letters()
  " returns a string padded between letters until given width with the given half-width character or white-space, considering non-half-width characters.
  call s:assert.equals( s:String.pad_between_letters('test', 11)       , '  t e s t  ')
  call s:assert.equals( s:String.pad_between_letters('テスト', 11)     , ' テ ス ト  ')
  call s:assert.equals( s:String.pad_between_letters('テスト', 12, '-'), '-テ--ス--ト-')
  call s:assert.equals( s:String.pad_between_letters('テスト', 13, '-'), '--テ--ス--ト-')
  call s:assert.equals( s:String.pad_between_letters('テスト', 14, '-'), '--テ--ス--ト--')
  call s:assert.equals( s:String.pad_between_letters('テスト', 15, '-'), '-テ---ス---ト--')
  call s:assert.equals( s:String.pad_between_letters('テスト', 16, '-'), '--テ---ス---ト--')
  " Can't use non-half-width characters for padding.
  try
    call s:String.pad_between_letters('test', 11, '＋')
    call s:assert.fail('pad_between_letters')
  catch
  endtry
endfunction

function! s:suite.justify_equal_spacing()
  " returns a string justified equals spacing with the given half-width character or white-space, considering non-half-width characters.
  call s:assert.equals( s:String.justify_equal_spacing('sushi', 12, '_'), 's__u__s__h_i')
  call s:assert.equals( s:String.justify_equal_spacing('中トロ', 12)    , '中   ト   ロ')
  call s:assert.equals( s:String.justify_equal_spacing('サーモン', 12)  , 'サ  ー モ ン')
  call s:assert.equals( s:String.justify_equal_spacing('ウニ', 12)      , 'ウ        ニ')
  call s:assert.equals( s:String.justify_equal_spacing('イクラ', 12)    , 'イ   ク   ラ')
  " Can't use non-half-width characters for padding.
  try
    call s:String.justify_equal_spacing('test', 11, '＋')
    call s:assert.fail('justify_equal_spacing')
  catch
  endtry
endfunction

function! s:suite.levenshtein_distance()
  " returns a minimum edit distance.
  call s:assert.equals( s:String.levenshtein_distance('kitten', 'sitting'), 3)
  call s:assert.equals( s:String.levenshtein_distance('', ''), 0)
  call s:assert.equals( s:String.levenshtein_distance('中トロ', ''), 3)
  call s:assert.equals( s:String.levenshtein_distance('', '大トロ'), 3)
  call s:assert.equals( s:String.levenshtein_distance('ちからうどん', 'からげんき'), 4)
endfunction

function! s:suite.split_by_displaywidth()
  let float = -1
  let width = 0
  call s:assert.equals(s:String.split_by_displaywidth('あaいbうcえdおe', width, float, 1), [''])
  call s:assert.equals(s:String.split_by_displaywidth('あaいbうcえdおe', width, float, 0), [''])
  call s:assert.equals(s:String.split_by_displaywidth("あaいb\nうc\nえdおe", width, float, 0), [''])
  call s:assert.equals(s:String.split_by_displaywidth("あaいb\nうc\nえdおe", width, float, 1), [''])

  let float = -1
  let width = 1
  call s:assert.equals(s:String.split_by_displaywidth('あaいbうcえdおe', width, float, 1), [' '])
  call s:assert.equals(s:String.split_by_displaywidth('あaいbうcえdおe', width, float, 0), [' '])
  call s:assert.equals(s:String.split_by_displaywidth('aあbいcうdえeお', width, float, 1), ['a', ' '])
  call s:assert.equals(s:String.split_by_displaywidth('aあbいcうdえeお', width, float, 0), ['a'])
  call s:assert.equals(s:String.split_by_displaywidth("あaいb\nうc\nえdおe", width, float, 0), [' ', ' ', ' ', ' ', ' '])
  call s:assert.equals(s:String.split_by_displaywidth("あaいb\nうc\nえdおe", width, float, 1), [' ', ' ', ' ', ' ', ' '])

  let float = -1
  let width = 2
  call s:assert.equals(s:String.split_by_displaywidth('12', width, float, 1), ['12'])
  call s:assert.equals(s:String.split_by_displaywidth('12', width, float, 0), ['12'])
  call s:assert.equals(s:String.split_by_displaywidth('あ12', width, float, 1), ['あ', '12'])
  call s:assert.equals(s:String.split_by_displaywidth('あ12', width, float, 0), ['あ'])
  call s:assert.equals(s:String.split_by_displaywidth('あ1', width, float, 1), ['あ', '1 '])
  call s:assert.equals(s:String.split_by_displaywidth('あ1', width, float, 0), ['あ'])

  let float = -1
  let width = 4
  call s:assert.equals(s:String.split_by_displaywidth("あaいb\nうc\nえdおe", width, float, 0), ['あa ', '    ', 'うc ', 'えd '])
  call s:assert.equals(s:String.split_by_displaywidth("あaいb\nうc\nえdおe", width, float, 1), ['あa ', 'いb ', 'うc ', 'えd ', 'おe '])

  let float = -1
  let width = 5
  call s:assert.equals(s:String.split_by_displaywidth('1234567890abcde', width, float, 1), ['12345', '67890', 'abcde'])
  call s:assert.equals(s:String.split_by_displaywidth('1234567890abcde', width, float, 0), ['12345'])
  call s:assert.equals(s:String.split_by_displaywidth('あaいbうcえdおe', width, float, 1), ['あaい', 'bうc ', 'えdお', 'e    '])
  call s:assert.equals(s:String.split_by_displaywidth('あaいbうcえdおe', width, float, 0), ['あaい'])
  call s:assert.equals(s:String.split_by_displaywidth('1234567890', width, float, 1), ['12345', '67890'])
  call s:assert.equals(s:String.split_by_displaywidth('1234567890', width, float, 0), ['12345'])
  call s:assert.equals(s:String.split_by_displaywidth('あいうえお', width, float, 1), ['あい ', 'うえ ', 'お   '])
  call s:assert.equals(s:String.split_by_displaywidth('あいうえお', width, float, 0), ['あい '])
  call s:assert.equals(s:String.split_by_displaywidth('12345678', width, float, 1), ['12345', '678  '])
  call s:assert.equals(s:String.split_by_displaywidth('12345678', width, float, 0), ['12345'])

  let float = -1
  let width = 6
  call s:assert.equals(s:String.split_by_displaywidth('1234567890abcde', width, float, 1), ['123456', '7890ab', 'cde   '])
  call s:assert.equals(s:String.split_by_displaywidth('1234567890abcde', width, float, 0), ['123456'])
  call s:assert.equals(s:String.split_by_displaywidth('1234567890', width, float, 1), ['123456', '7890  '])
  call s:assert.equals(s:String.split_by_displaywidth('1234567890', width, float, 0), ['123456'])
  call s:assert.equals(s:String.split_by_displaywidth('あいうえお', width, float, 1), ['あいう', 'えお  '])
  call s:assert.equals(s:String.split_by_displaywidth('あいうえお', width, float, 0), ['あいう'])
  call s:assert.equals(s:String.split_by_displaywidth('12345678', width, float, 1), ['123456', '78    '])
  call s:assert.equals(s:String.split_by_displaywidth('12345678', width, float, 0), ['123456'])
  call s:assert.equals(s:String.split_by_displaywidth('12', width, float, 1), ['12    '])
  call s:assert.equals(s:String.split_by_displaywidth('12', width, float, 0), ['12    '])

  let float = 0
  let width = 5
  call s:assert.equals(s:String.split_by_displaywidth('あいうえお', width, float, 1), ['あい ', 'うえ ', ' お  '])
  let float = 0
  let width = 3
  call s:assert.equals(s:String.split_by_displaywidth('あいうえお', width, float, 1), ['あ ', 'い ', 'う ', 'え ', 'お '])

  let float = 1
  let width = 5
  call s:assert.equals(s:String.split_by_displaywidth('あいうえお', width, float, 1), [' あい', ' うえ', '   お'])
  let float = 1
  let width = 3
  call s:assert.equals(s:String.split_by_displaywidth('あいうえお', width, float, 1), [' あ', ' い', ' う', ' え', ' お'])

endfunction
"
function! s:suite.padding_by_displaywidth()
  let width = 6
  call s:assert.equals(s:String.padding_by_displaywidth('abc', width, -1), 'abc   ')
  call s:assert.equals(s:String.padding_by_displaywidth('abc', width, 1),  '   abc')
  call s:assert.equals(s:String.padding_by_displaywidth('abc', width, 0),  ' abc  ')
  call s:assert.equals(s:String.padding_by_displaywidth('abcdefgh', width, -1),  'abcdefgh')
  call s:assert.equals(s:String.padding_by_displaywidth('abcdefgh', width, 0),  'abcdefgh')
  call s:assert.equals(s:String.padding_by_displaywidth('abcdefgh', width, 1),  'abcdefgh')

  let width = 5
  call s:assert.equals(s:String.padding_by_displaywidth('abc', width, -1), 'abc  ')
  call s:assert.equals(s:String.padding_by_displaywidth('abc', width, 0),  ' abc ')
  call s:assert.equals(s:String.padding_by_displaywidth('abc', width, 1),  '  abc')
  call s:assert.equals(s:String.padding_by_displaywidth('abcdefgh', width, -1),  'abcdefgh')
  call s:assert.equals(s:String.padding_by_displaywidth('abcdefgh', width, 0),  'abcdefgh')
  call s:assert.equals(s:String.padding_by_displaywidth('abcdefgh', width, 1),  'abcdefgh')

  let width = 0
  call s:assert.equals(s:String.padding_by_displaywidth('abc', width, -1), 'abc')
  call s:assert.equals(s:String.padding_by_displaywidth('abc', width, 0), 'abc')
  call s:assert.equals(s:String.padding_by_displaywidth('abc', width, 1), 'abc')
  "
  let width = -3
  call s:assert.equals(s:String.padding_by_displaywidth('abc', width, -1), 'abc')
  call s:assert.equals(s:String.padding_by_displaywidth('abc', width, 0), 'abc')
  call s:assert.equals(s:String.padding_by_displaywidth('abc', width, 1), 'abc')

  let width = 12
  call s:assert.equals(s:String.padding_by_displaywidth('あいう'   , width, -1), 'あいう      ')
  call s:assert.equals(s:String.padding_by_displaywidth('あいう'   , width, 0), '   あいう   ')
  call s:assert.equals(s:String.padding_by_displaywidth('あいう'   , width, 1), '      あいう')
  call s:assert.equals(s:String.padding_by_displaywidth('あaいbうc', width, -1), 'あaいbうc   ')
  call s:assert.equals(s:String.padding_by_displaywidth('あaいbうc', width, 0), ' あaいbうc  ')
  call s:assert.equals(s:String.padding_by_displaywidth('あaいbうc', width, 1), '   あaいbうc')
  call s:assert.equals(s:String.padding_by_displaywidth('あいうえおかき', width, -1), 'あいうえおかき')
  call s:assert.equals(s:String.padding_by_displaywidth('あいうえおかき', width, 0), 'あいうえおかき')
  call s:assert.equals(s:String.padding_by_displaywidth('あいうえおかき', width, 1), 'あいうえおかき')

  let width = 0
  call s:assert.equals(s:String.padding_by_displaywidth('あいう'   , width, -1), 'あいう')
  call s:assert.equals(s:String.padding_by_displaywidth('あaいbうc', width, 0), 'あaいbうc')
  call s:assert.equals(s:String.padding_by_displaywidth('あいうえおかき', width, 1), 'あいうえおかき')

  let width = -2
  call s:assert.equals(s:String.padding_by_displaywidth('あいう'   , width, -1), 'あいう')
  call s:assert.equals(s:String.padding_by_displaywidth('あaいbうc', width, 0), 'あaいbうc')
  call s:assert.equals(s:String.padding_by_displaywidth('あいうえおかき', width, 1), 'あいうえおかき')

endfunction

function! s:suite.hash()
  "
  " Test by property
  " TODO use something like quickcheck once themis add it.
  "
  for str1 in ['', 'sample text', "longer\ntest\nexample", 'サンプルテキスト']
    " Hashed strings should be different to original strings
    call s:assert.not_equals(str1, s:String.hash(str1))

    for str2 in ['', 'sample text', "longer\ntest\nexample", 'サンプルテキスト']
      if str1 ==# str2
        " This is idempotent; hashed strings with same string should equal
        call s:assert.equals(s:String.hash(str1), s:String.hash(str2))
      else
        " Hashed strings should be different if original strings are different
        call s:assert.not_equals(s:String.hash(str1), s:String.hash(str2))
      endif
    endfor
  endfor

  " Test by concrete values
  if exists('*sha256')
    call s:assert.equals('45d233b7fdfe9fcac08ec47c797a8d99bebfb0718b9d2acbcdf50df7d6aeb84c', s:String.hash('ujihisa'))
  else
    call s:assert.equals('b8a', s:String.hash('ujihisa'))
  endif
endfunction

function! s:suite.truncate()
  call s:assert.equals(s:String.truncate('this is a pen', -1), '')
  call s:assert.equals(s:String.truncate('this is a pen', 0), '')
  call s:assert.equals(s:String.truncate('this is a pen', 2), 'th')
  call s:assert.equals(s:String.truncate('this is a pen', 13), 'this is a pen')
  call s:assert.equals(s:String.truncate('this is a pen', 20), 'this is a pen       ')
  call s:assert.equals(s:String.truncate('あいうえお', -1), '')
  call s:assert.equals(s:String.truncate('あいうえお', 1), ' ')
  call s:assert.equals(s:String.truncate('あいうえお', 2), 'あ')
  call s:assert.equals(s:String.truncate('あいうえお', 8), 'あいうえ')
  call s:assert.equals(s:String.truncate('あいうえお', 9), 'あいうえ ')
  call s:assert.equals(s:String.truncate('あいうえお', 15), 'あいうえお     ')
endfunction

function! s:suite.truncate_skipping()
  call s:assert.equals(s:String.truncate_skipping('this is a pen', 10, 1, '/'), 'this is /n')
  call s:assert.equals(s:String.truncate_skipping('this is a pen', 10, 3, '...'), 'this...pen')
  call s:assert.equals(s:String.truncate_skipping('this is a pen', 20, 3, '...'), 'this is a pen       ')
  call s:assert.equals(s:String.truncate_skipping('this is a pen', 10, 3, '...................'), '..........')
  call s:assert.equals(s:String.truncate_skipping('あいうえおかきくけこ.', 10, 1, '/'), 'あいうえ/.')
  call s:assert.equals(s:String.truncate_skipping('あいうえおかきくけこ', 10, 2, ' .. '), 'あい .. こ')
  call s:assert.equals(s:String.truncate_skipping('あいうえおかきくけこ', 15, 2, ' .. '), 'あいうえ .. こ ')
  call s:assert.equals(s:String.truncate_skipping('あいうえおかきくけこ', 20, 2, ' .. '), 'あいうえおかきくけこ')
endfunction

function! s:suite.strwidthpart()
  call s:assert.equals(s:String.strwidthpart('', 0), '')
  call s:assert.equals(s:String.strwidthpart('', 1), '')
  call s:assert.equals(s:String.strwidthpart('a', 1), 'a')
  call s:assert.equals(s:String.strwidthpart('ab', 2), 'ab')
  call s:assert.equals(s:String.strwidthpart('this is a pen', -1), '')
  call s:assert.equals(s:String.strwidthpart('this is a pen', 0), '')
  call s:assert.equals(s:String.strwidthpart('this is a pen', 5), 'this ')
  call s:assert.equals(s:String.strwidthpart('this is a pen', 20), 'this is a pen')
  call s:assert.equals(s:String.strwidthpart('あ', 1), '')
  call s:assert.equals(s:String.strwidthpart('あ', 2), 'あ')
  call s:assert.equals(s:String.strwidthpart('あいうえお', -1), '')
  call s:assert.equals(s:String.strwidthpart('あいうえお', 0), '')
  call s:assert.equals(s:String.strwidthpart('あいうえお', 5), 'あい')
  call s:assert.equals(s:String.strwidthpart('あいうえお', 6), 'あいう')
  call s:assert.equals(s:String.strwidthpart('あいうえお', 10), 'あいうえお')
  call s:assert.equals(s:String.strwidthpart('あいうえお', 20), 'あいうえお')
endfunction

function! s:suite.strwidthpart_reverse()
  call s:assert.equals(s:String.strwidthpart_reverse('a', 1), 'a')
  call s:assert.equals(s:String.strwidthpart_reverse('this is a pen', -1), '')
  call s:assert.equals(s:String.strwidthpart_reverse('this is a pen', 0), '')
  call s:assert.equals(s:String.strwidthpart_reverse('this is a pen', 5), 'a pen')
  call s:assert.equals(s:String.strwidthpart_reverse('this is a pen', 20), 'this is a pen')
  call s:assert.equals(s:String.strwidthpart_reverse('あ', 1), '')
  call s:assert.equals(s:String.strwidthpart_reverse('あ', 2), 'あ')
  call s:assert.equals(s:String.strwidthpart_reverse('あいうえお', -1), '')
  call s:assert.equals(s:String.strwidthpart_reverse('あいうえお', 0), '')
  call s:assert.equals(s:String.strwidthpart_reverse('あいうえお', 5), 'えお')
  call s:assert.equals(s:String.strwidthpart_reverse('あいうえお', 6), 'うえお')
  call s:assert.equals(s:String.strwidthpart_reverse('あいうえお', 10), 'あいうえお')
  call s:assert.equals(s:String.strwidthpart_reverse('あいうえお', 20), 'あいうえお')
endfunction
