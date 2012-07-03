source spec/base.vim
scriptencoding utf-8

let g:B = vital#of('vital').import('Data.Base64')

Context Data.Base64.encode()
  It encode string to base64 encoded string.
    Should 'aGVsbG8sIHdvcmxkIQ==' ==# g:B.encode("hello, world!")
  End
End

Context Data.Base64.encodebin()
  It encode string encoded as hex to base64 encoded string.
    Should 'aGVsbG8sIHdvcmxkIQ==' ==# g:B.encodebin('68656c6c6f2c20776f726c6421')
  End
End

Context Data.Base64.decode()
  It decode base64 encoded string to string.
    Should 'hello, world!' ==# g:B.decode("aGVsbG8sIHdvcmxkIQ==")
  End
End
