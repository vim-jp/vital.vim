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
  End
End

Context Data.String.strchars()
  It returns the number of character, not byte
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
