source spec/base.vim
scriptencoding utf-8

let g:S = vital#of('vital').import('Data.String')

Context Data.String.wrap()
  It makes a list from the given string, considering linebreak and width like wrap option
    Should ['a', 'hello, world!'] ==# g:S.wrap("a\nhello, world!")
    let [&columns, columns] = [12, &columns]
    Should ['a', 'hello, worl', 'd!'] ==# g:S.wrap("a\nhello, world!")
    let &columns = columns
  End
End

Context Data.String.replace()
  It substitutes arg2 to arg3 from arg1
    " TODO: Write common tests in one place
    " Common tests for replace(), replace_once()
    Should g:S.replace('foobar', 'ob', '') ==# 'foar'
    Should g:S.replace('foobar', 'foo', '') ==# 'bar'
    Should g:S.replace('foobar', 'ar', '') ==# 'foob'
    Should g:S.replace('', 'foo', '') ==# ''
    Should g:S.replace('foobar', '', '') ==# 'foobar'
    " FIXME: this causes infinite loop
    " Should g:S.replace('foobar', 'bar', 'barbaz') ==# 'foobarbaz'
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
  End
End

Context Data.String.replace_once()
  It is like Data.String.replace(), but this substitutes the first matching substring, not all
    " TODO: Write common tests in one place
    " Common tests for replace(), replace_once()
    Should g:S.replace_once('foobar', 'ob', '') ==# 'foar'
    Should g:S.replace_once('foobar', 'foo', '') ==# 'bar'
    Should g:S.replace_once('foobar', 'ar', '') ==# 'foob'
    Should g:S.replace_once('', 'foo', '') ==# ''
    Should g:S.replace_once('foobar', '', '') ==# 'foobar'
    " FIXME: this causes infinite loop
    " Should g:S.replace_once('foobar', 'bar', 'barbaz') ==# 'foobarbaz'
    Should g:S.replace_once('foobar', 'bar', 'baz') ==# 'foobaz'

    " Specific tests for Data.String.replace_once()
    Should g:S.replace_once('hello', 'l', '') ==# 'helo'
    Should g:S.replace_once('hello', 'l', 'L') ==# 'heLlo'
    Should g:S.replace_once('hello', 'l', 'LL') ==# 'heLLlo'
    Should g:S.replace_once('queue', 'ue', '') ==# 'que'
    Should g:S.replace_once('queue', 'ue', 'u') ==# 'quue'
    Should g:S.replace_once('queue', 'ue', 'uu') ==# 'quuue'
    Should g:S.replace_once('mimic', 'mi', '') ==# 'mic'
    Should g:S.replace_once('mimic', 'mi', 'm') ==# 'mmic'
    Should g:S.replace_once('mimic', 'mi', 'mm') ==# 'mmmic'
  End
End

Context Data.String.scan()
  It scans a string by a pattern and returns a list of matched strings
    Should g:S.scan('neo compl cache', 'c\w\+') == ['compl', 'cache']
    Should g:S.scan('[](){}', '[{()}]') == ['(', ')', '{', '}']
    Should g:S.scan('string', '.*') == ['string']
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
  It returns an empty string with empty list
    Should g:S.common_head([]) ==# ''
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
