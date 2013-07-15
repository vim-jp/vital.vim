source spec/base.vim

let s:V = vital#of('vital')
let s:L = s:V.import('Text.Lexer')

let patterns = [
\ ['WHITE_SPACES','\s\+'],
\ ['WORD','[a-zA-Z]\+'],
\ ['DIGIT','[0-9]\+'],
\ ]
let lex = s:L.lexer(patterns)
let tokens = lex.exec('orange melon 123 banana')
"                      0123456789012345678901

Context Text.Lexer.lexer()
  It makes a new dictionary from keys and values
    Should [] == lex.exec('')
    Should [
    \   {'label': 'WORD', 'col': 0, 'matched_text': 'hoge'},
    \   {'label': 'WHITE_SPACES', 'col': 4, 'matched_text': ' '},
    \   {'label': 'WORD', 'col': 5, 'matched_text': 'foo'}
    \   ] == lex.exec('hoge foo')
    Should len(tokens) == 7
    Should tokens[0] == {'label': 'WORD', 'col': 0, 'matched_text': 'orange'}
    Should tokens[1] == {'label': 'WHITE_SPACES', 'col': 6, 'matched_text': ' '}
    Should tokens[2] == {'label': 'WORD', 'col': 7, 'matched_text': 'melon'}
    Should tokens[3] == {'label': 'WHITE_SPACES', 'col': 12, 'matched_text': ' '}
    Should tokens[4] == {'label': 'DIGIT', 'col': 13, 'matched_text': '123'}
    Should tokens[5] == {'label': 'WHITE_SPACES', 'col': 16, 'matched_text': ' '}
    Should tokens[6] == {'label': 'WORD', 'col': 17, 'matched_text': 'banana'}
  End

  It throws an error when arg has unknown patterns
    try
      call lex.exec('hoge 123 @@@')
      Should 0
    catch
      Should 1
    endtry
  End

  It throws an error when invalid parameter
    try
      call s:L.lexer('hoge')
      Should 0
    catch
      Should 1
    endtry

    try
      call s:L.lexer([['word']])
      Should 0
    catch
      Should 1
    endtry

    try
      call s:L.lexer([['word', '2', '3']])
      Should 0
    catch
      Should 1
    endtry

    try
      call s:L.lexer([['word', 2]])
      Should 0
    catch
      Should 1
    endtry
  End
End


Context Text.Lexer.simpl_parser()
  It makes simple_parser
    let parser = s:L.simple_parser(tokens)

    for idx in range(len(tokens))
      Should parser.end() == 0
      for label in ['WHITE_SPACES', 'WORD', 'DIGIT', 'HOGE']
        Should parser.next_is(label) == (tokens[idx].label == label)
      endfor
      Should parser.next() == tokens[idx]
      Should parser.end() == 0
      Should parser.next() == tokens[idx]
      Should parser.end() == 0
      Should parser.consume() == tokens[idx]
    endfor
    Should parser.end() == 1
    try
      call parser.next()
      Should 0
    catch
      Should 1
    endtry
    try
      call parser.next_is()
      Should 0
    catch
      Should 1
    endtry
    try
      call parser.consume()
      Should 0
    catch
      Should 1
    endtry
End
