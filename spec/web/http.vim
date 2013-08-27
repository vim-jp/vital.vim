source spec/base.vim

let g:H = vital#of('vital').import('Web.HTTP')

Context Web.Http.encodeURI()
  It encodes string
    for s in ['1234567890',
    \  'abcdefghijklmnopqrstuvwxyz',
    \  'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    \  '._-',
    \  'abc1.2345_ABCD-EZY']
      Should s == g:H.encodeURI(s)
    endfor
    Should 'abc12390' == g:H.encodeURI('abc12390')
    Should 'abc%01%0A%0D%20AB-' == g:H.encodeURI("abc\x01\x0a\x0d AB-")
    Should '%A4%C1%A4%E3' == g:H.encodeURI("\xA4\xC1\xA4\xE3")
    Should '%A4%C1%A4%E5' == g:H.encodeURI("\xA4\xC1\xA4\xE5")
    Should '%A4%C1%A4%E7' == g:H.encodeURI("\xA4\xC1\xA4\xE7")
  End
End
Context Web.Http.decodeURI()
  It decodes string
    for s in ['1234567890',
    \  'abcdefghijklmnopqrstuvwxyz',
    \  'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    \  'abc12345ABCDEZY',
    \  '._-',
    \  'abc1.2345_ABCD-EZY']
      Should s == g:H.decodeURI(s)
    endfor
    Should '1234567890' == g:H.decodeURI('1234567890')
    Should 'abc12390' == g:H.decodeURI('abc12390')
    Should g:H.decodeURI('%A4%C1%A4%E3') == "\xA4\xC1\xA4\xE3"
    Should g:H.decodeURI('%A4%C1%A4%E5') == "\xA4\xC1\xA4\xE5"
    Should g:H.decodeURI('%A4%C1%A4%E7') == "\xA4\xC1\xA4\xE7"
  End

  It encodes and decodes string
    for s in ['1234567890',
    \  'abcdefghijklmnopqrstuvwxyz',
    \  'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    \  'abc12345ABCDEZY',
    \  '%123ABC!"#$%&''()~=-~^|\\[]@:;+<>/\',
    \  'あいうえお',
    \  'ちゃちゅちょ']
      Should s == g:H.decodeURI(g:H.encodeURI(s))
    endfor
  End
End


" vim:set et ts=2 sts=2 sw=2 tw=0:
