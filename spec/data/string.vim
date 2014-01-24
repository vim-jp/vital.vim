source spec/base.vim
scriptencoding utf-8

let g:S = vital#of('vital').import('Data.String')

Context Data.String.wrap()
  It makes a list from the given string, considering linebreak and width like wrap option
    Should ['a', 'hello, world!'] ==# g:S.wrap("a\nhello, world!")
    Should ['a', 'hello, world!'] ==# g:S.wrap("a\r\nhello, world!")
    Should ['a', 'hello, world!'] ==# g:S.wrap("a\rhello, world!")
    let [&columns, columns] = [12, &columns]
    Should ['a', 'hello, worl', 'd!'] ==# g:S.wrap("a\nhello, world!")
    let &columns = columns
  End
End

Context Data.String.replace()
  It substitutes arg2 to arg3 from arg1
    " TODO: Write common tests in one place
    " Common tests for replace(), replace_first()
    Should g:S.replace('foobar', 'ob', '') ==# 'foar'
    Should g:S.replace('foobar', 'foo', '') ==# 'bar'
    Should g:S.replace('foobar', 'ar', '') ==# 'foob'
    Should g:S.replace('', 'foo', '') ==# ''
    Should g:S.replace('foobar', '', '') ==# 'foobar'
    Should g:S.replace('foobar', 'bar', 'barbaz') ==# 'foobarbaz'
    Should g:S.replace('foobar', 'bar', 'baz') ==# 'foobaz'

    " Specific tests for Data.String.replace()
    Should g:S.replace('hello', 'l', '') ==# 'heo'
    Should g:S.replace('hello', 'l', 'L') ==# 'heLLo'
    Should g:S.replace('hello', 'l', 'LL') ==# 'heLLLLo'
    Should g:S.replace('queue', 'ue', '') ==# 'q'
    Should g:S.replace('queue', 'ue', 'u') ==# 'quu'
    Should g:S.replace('queue', 'ue', 'uu') ==# 'quuuu'
    Should g:S.replace('mimic', 'mi', '') ==# 'c'
    Should g:S.replace('mimic', 'mi', 'm') ==# 'mmc'
    Should g:S.replace('mimic', 'mi', 'mm') ==# 'mmmmc'
    Should g:S.replace('\(.*\)', '.', '') ==# '\(*\)'
    Should g:S.replace('\v.\m.\M.', '.', '') ==# '\v\m\M'
    Should g:S.replace('\v.\m.\M.', '\', '') ==# 'v.m.M.'
    Should g:S.replace('\(.*\)', '.', '\0') ==# '\(\0*\)'
    Should g:S.replace('\(.*\)', '.', '\=submatch(1)') ==# '\(\=submatch(1)*\)'
  End
End

Context Data.String.replace_first()
  It is like Data.String.replace(), but this substitutes the first matching substring, not all
    " TODO: Write common tests in one place
    " Common tests for replace(), replace_first()
    Should g:S.replace_first('foobar', 'ob', '') ==# 'foar'
    Should g:S.replace_first('foobar', 'foo', '') ==# 'bar'
    Should g:S.replace_first('foobar', 'ar', '') ==# 'foob'
    Should g:S.replace_first('', 'foo', '') ==# ''
    Should g:S.replace_first('foobar', '', '') ==# 'foobar'
    Should g:S.replace_first('foobar', 'bar', 'barbaz') ==# 'foobarbaz'
    Should g:S.replace_first('foobar', 'bar', 'baz') ==# 'foobaz'

    " Specific tests for Data.String.replace_first()
    Should g:S.replace_first('hello', 'l', '') ==# 'helo'
    Should g:S.replace_first('hello', 'l', 'L') ==# 'heLlo'
    Should g:S.replace_first('hello', 'l', 'LL') ==# 'heLLlo'
    Should g:S.replace_first('queue', 'ue', '') ==# 'que'
    Should g:S.replace_first('queue', 'ue', 'u') ==# 'quue'
    Should g:S.replace_first('queue', 'ue', 'uu') ==# 'quuue'
    Should g:S.replace_first('mimic', 'mi', '') ==# 'mic'
    Should g:S.replace_first('mimic', 'mi', 'm') ==# 'mmic'
    Should g:S.replace_first('mimic', 'mi', 'mm') ==# 'mmmic'
    Should g:S.replace_first('\(.*\)', '.', '') ==# '\(*\)'
    Should g:S.replace_first('\v.\m.\M.', '.', '') ==# '\v\m.\M.'
    Should g:S.replace_first('\v.\m.\M.', '\', '') ==# 'v.\m.\M.'
    Should g:S.replace_first('\(.*\)', '.', '\0') ==# '\(\0*\)'
    Should g:S.replace_first('\(.*\)', '.', '\=submatch(1)') ==# '\(\=submatch(1)*\)'
  End
End

Context Data.String.scan()
  It scans a string by a pattern and returns a list of matched strings
    Should g:S.scan('neo compl cache', 'c\w\+') == ['compl', 'cache']
    Should g:S.scan('[](){}', '[{()}]') == ['(', ')', '{', '}']
    Should g:S.scan('string', '.*') == ['string']
    Should g:S.scan('string', '.\zs') == ['', '', '', '', '', '']
    Should g:S.scan('string', '') == ['', '', '', '', '', '', '']
  End
End

Context Data.String.reverse()
  It returns a reversed string
    Should g:S.reverse('string') ==# 'gnirts'
    Should g:S.reverse('') ==# ''
  End
  It works on character base
    Should g:S.reverse('あいうえお') ==# 'おえういあ'
  End
End

Context Data.String.common_head()
  It returns common part of head of strings
    Should g:S.common_head(['neocomplcache', 'neosnippet', 'neobundle']) ==# 'neo'
    Should g:S.common_head(['neocomplcache', 'vimshell']) ==# ''
  End
  It returns an empty string if empty string in list
    Should g:S.common_head(['neocomplcache', '']) ==# ''
    Should g:S.common_head(['', 'neocomplcache']) ==# ''
    Should g:S.common_head(['', '']) ==# ''
    Should g:S.common_head(['']) ==# ''
    End
  It returns an empty string with empty list
    Should g:S.common_head([]) ==# ''
  End
  It is safe for regexp characters
    try
      Should g:S.common_head(['^o^', '^oo^']) ==# '^o'
      Should g:S.common_head(['\', '\']) ==# '\'
      Should g:S.common_head(['*_*', '*_*']) ==# '*_*'
      Should g:S.common_head(['...-..--', '...-..--']) ==# '...-..--'
      Should g:S.common_head(['[', '[']) ==# '['
      Should g:S.common_head([']', ']']) ==# ']'
    catch
      Should 0
    endtry
  End
End

Context Data.String.split3()
  It splits into two substrings: left/right substring next to matched string with pattern
    Should g:S.split3('neocomplcache', 'compl') ==# ['neo', 'compl', 'cache']
    Should g:S.split3('autocomplpop', 'compl') ==# ['auto', 'compl', 'pop']
    Should g:S.split3('neocomplcache', 'neo') ==# ['', 'neo', 'complcache']
    Should g:S.split3('autocomplpop', 'auto') ==# ['', 'auto', 'complpop']
    Should g:S.split3('neocomplcache', 'cache') ==# ['neocompl', 'cache', '']
    Should g:S.split3('autocomplpop', 'pop') ==# ['autocompl', 'pop', '']
    " Invalid arguments
    Should g:S.split3('', 'compl') ==# ['', '', '']
    Should g:S.split3('neo', '') ==# ['', '', '']
    Should g:S.split3('', '') ==# ['', '', '']
    " No match
    Should g:S.split3('neocomplcache', 'neocon') ==# ['', '', '']
    Should g:S.split3('neocomplcache', 'neco') ==# ['', '', '']
    " Pattern
    Should g:S.split3('neocomplcache', '...\zs.....') ==# ['neo', 'compl', 'cache']
    Should g:S.split3('neocomplcache', '.\zs..\ze.....') ==# ['n', 'eo', 'complcache']
    Should g:S.split3('neocomplcache', '........') ==# ['', 'neocompl', 'cache']
    Should g:S.split3('neocomplcache', '........\zs....\ze.') ==# ['neocompl', 'cach', 'e']
    Should g:S.split3('neocomplcache', 'neo\zscompl.....') ==# ['neo', 'complcache', '']
  End
End

Context Data.String.split_leftright()
  It splits into two substrings: left/right substring next to matched string with pattern
    Should g:S.split_leftright('neocomplcache', 'compl') ==# ['neo', 'cache']
    Should g:S.split_leftright('autocomplpop', 'compl') ==# ['auto', 'pop']
    Should g:S.split_leftright('neocomplcache', 'neo') ==# ['', 'complcache']
    Should g:S.split_leftright('autocomplpop', 'auto') ==# ['', 'complpop']
    Should g:S.split_leftright('neocomplcache', 'cache') ==# ['neocompl', '']
    Should g:S.split_leftright('autocomplpop', 'pop') ==# ['autocompl', '']
    " Invalid arguments
    Should g:S.split_leftright('', 'compl') ==# ['', '']
    Should g:S.split_leftright('neo', '') ==# ['', '']
    Should g:S.split_leftright('', '') ==# ['', '']
    " No match
    Should g:S.split_leftright('neocomplcache', 'neocon') ==# ['', '']
    Should g:S.split_leftright('neocomplcache', 'neco') ==# ['', '']
    " Pattern
    Should g:S.split_leftright('neocomplcache', '...\zs.....') ==# ['neo', 'cache']
    Should g:S.split_leftright('neocomplcache', '.\zs..\ze.....') ==# ['n', 'complcache']
    Should g:S.split_leftright('neocomplcache', '........') ==# ['', 'cache']
    Should g:S.split_leftright('neocomplcache', '........\zs....\ze.') ==# ['neocompl', 'e']
    Should g:S.split_leftright('neocomplcache', 'neo\zscompl.....') ==# ['neo', '']
  End
End

Context Data.String.strchars()
  It returns the number of character, not byte
    Should g:S.strchars('this') ==# 4
    Should g:S.strchars('あいうえお') ==# 5
    Should g:S.strchars('aiueo') ==# 5
    Should g:S.strchars('') ==# 0
    Should g:S.strchars('あiうeお') ==# 5
    Should g:S.strchars('aいuえo') ==# 5
    if &ambiwidth ==# 'single'
        Should g:S.strchars('Shougo△') ==# 7
    elseif &ambiwidth ==# 'double'
        Should g:S.strchars('Shougo△') ==# 8
    elseif &ambiwidth ==# 'auto'
        " TODO: I don't know +kaoriya version's "auto" behavior...
    else
        " wtf?
        let be_nonsense = 0
        Should be_nonsense
    endif
  End
End

Context Data.String.nsplit()
  It splits into strings determines number with pattern
    Should g:S.nsplit('neo compl_cache', 2, '[ _]') ==# ['neo', 'compl_cache']
    Should g:S.nsplit('neo compl_cache', 3, '[ _]') ==# ['neo', 'compl', 'cache']
    Should g:S.nsplit('neo compl__cache', 2, '[ _]') ==# ['neo', 'compl__cache']
    Should g:S.nsplit('neo compl__cache', 3, '[ _]') ==# ['neo', 'compl', '_cache']
    Should g:S.nsplit('neo compl__cache', 4, '[ _]') ==# ['neo', 'compl', '', 'cache']
    Should g:S.nsplit('neo compl__cache', 2, '[ _]', 0) ==# ['neo', 'compl__cache']
    Should g:S.nsplit('neo compl__cache', 3, '[ _]', 0) ==# ['neo', 'compl', '_cache']
    Should g:S.nsplit('neo compl__cache', 4, '[ _]', 0) ==# ['neo', 'compl', 'cache']
  End
End

Context Data.String.diffidx()
  It returns the index of string that found a different
    Should g:S.diffidx('abcde', 'abdce') ==# 2
    Should g:S.diffidx('', '') ==# -1
    Should g:S.diffidx('', 'a') ==# 0
    Should g:S.diffidx('a', '') ==# 0
    Should g:S.diffidx('a', 'ab') ==# 1
    Should g:S.diffidx('a', 'a') ==# -1
    Should g:S.diffidx('▽', '▼') ==# 0
  End
End

Context Data.String.substitute_last()
  It makes new string substituting a given string with the given regexp pattern, but only the last matched part.
    Should g:S.substitute_last('vital is vim', 'i', 'ooo') ==# 'vital is vooom'
  End
End

Context Data.String.dstring()
  It wraps the result string not with single-quotes but with double-quotes.
    Should g:S.dstring(123) == '"123"'
    Should g:S.dstring('abc') == '"abc"'
    Should g:S.dstring("abc") == '"abc"'
  End
End

Context Data.String.lines()
  It splits into list of strings of each lines of {str}.
    Should g:S.lines("a\nb\r\nc") == ['a', 'b', 'c']
  End
End

Context Data.String.contains_multibyte()
  It returns 1 if the string contains multibyte
    Should g:S.contains_multibyte('あ') == 1
    Should g:S.contains_multibyte('a') == 0
    Should g:S.contains_multibyte('aあ') == 1
    Should g:S.contains_multibyte('aあa') == 1
    Should g:S.contains_multibyte('') == 0
  End
End

Context Data.String.pad_left()
  It returns a string padded left side until given width with the given half-width character or white-space, considering non-half-width characters.
    Should g:S.pad_left('test', 11)        == '       test'
    Should g:S.pad_left('テスト', 11)      == '     テスト'
    Should g:S.pad_left('テスト', 11, '-') == '-----テスト'
    " Can't use non-half-width characters for padding.
    try
      call g:S.pad_left('test', 11, '―')
      Should 1
    catch
      Should 0
    endtry
  End
End

Context Data.String.pad_right()
  It returns a string padded right side until given width with the given half-width character or white-space, considering non-half-width characters.
    Should g:S.pad_right('test', 11)        == 'test       '
    Should g:S.pad_right('テスト', 11)      == 'テスト     '
    Should g:S.pad_right('テスト', 11, '-') == 'テスト-----'
    " Can't use non-half-width characters for padding.
    try
      call g:S.pad_right('test', 11, '―')
      Should 1
    catch
      Should 0
    endtry
  End
End

Context Data.String.pad_both_sides()
  It returns a string padded left and right side until given width with the given half-width character or white-space, considering non-half-width characters.
    Should g:S.pad_both_sides('test', 11)        == '   test    '
    Should g:S.pad_both_sides('テスト', 11)      == '  テスト   '
    Should g:S.pad_both_sides('テスト', 11, '-') == '--テスト---'
    " Can't use non-half-width characters for padding.
    try
      call g:S.pad_both_sides('test', 11, '―')
      Should 1
    catch
      Should 0
    endtry
  End
End

Context Data.String.pad_between_letters()
  It returns a string padded between letters until given width with the given half-width character or white-space, considering non-half-width characters.
    Should g:S.pad_between_letters('test', 11)        == '  t e s t  '
    Should g:S.pad_between_letters('テスト', 11)      == ' テ ス ト  '
    Should g:S.pad_between_letters('テスト', 12, '-') == '-テ--ス--ト-'
    Should g:S.pad_between_letters('テスト', 13, '-') == '--テ--ス--ト-'
    Should g:S.pad_between_letters('テスト', 14, '-') == '--テ--ス--ト--'
    Should g:S.pad_between_letters('テスト', 15, '-') == '-テ---ス---ト--'
    Should g:S.pad_between_letters('テスト', 16, '-') == '--テ---ス---ト--'
    " Can't use non-half-width characters for padding.
    try
      call g:S.pad_between_letters('test', 11, '―')
      Should 1
    catch
      Should 0
    endtry
  End
End

