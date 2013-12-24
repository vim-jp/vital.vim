source spec/base.vim

let s:V = vital#of('vital')
let g:L = s:V.import('Text.Lexer')

let patterns = [
\ ['WHITE_SPACES','\s\+'],
\ ['WORD','[a-zA-Z]\+'],
\ ['DIGIT','[0-9]\+'],
\ ]
let g:lex = g:L.lexer(patterns)
let tokens = g:lex.exec('orange melon 123 banana')
"                      0123456789012345678901

Context Text.Lexer.lexer()
  It makes a new dictionary from keys and values
    Should [] == g:lex.exec('')
    Should [
    \   {'label': 'WORD', 'col': 0, 'matched_text': 'hoge'},
    \   {'label': 'WHITE_SPACES', 'col': 4, 'matched_text': ' '},
    \   {'label': 'WORD', 'col': 5, 'matched_text': 'foo'}
    \   ] == g:lex.exec('hoge foo')
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
    ShouldThrow g:lex.exec('hoge 123 @@@'), /.*/
  End

  It throws an error when invalid parameter
    ShouldThrow g:L.lexer('hoge'), /.*/
    ShouldThrow g:L.lexer([['word']]), /.*/
    ShouldThrow g:L.lexer([['word', '2', '3']]), /.*/
    ShouldThrow g:L.lexer([['word', 2]]), /.*/
  End
End


Context Text.Lexer.simple_parser()
  It makes simple_parser
    let g:parser = g:L.simple_parser(tokens)

    for idx in range(len(tokens))
      Should g:parser.end() == 0
      for label in ['WHITE_SPACES', 'WORD', 'DIGIT', 'HOGE']
        Should g:parser.next_is(label) == (tokens[idx].label == label)
      endfor
      Should g:parser.next() == tokens[idx]
      Should g:parser.end() == 0
      Should g:parser.next() == tokens[idx]
      Should g:parser.end() == 0
      Should g:parser.consume() == tokens[idx]
    endfor
    Should g:parser.end() == 1

    ShouldThrow g:parser.next(), /.*/
    ShouldThrow g:parser.next_is('WORD'), /.*/
    ShouldThrow g:parser.consume(), /.*/
End

