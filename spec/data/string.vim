source spec/base.vim

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
  End
End
