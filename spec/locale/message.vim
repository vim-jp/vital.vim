scriptencoding utf-8

source spec/base.vim

let g:M = vital#of('vital').import('Locale.Message')

let s:text_path = 'spec/locale/message_text/%s.txt'


Context Locale.Message.get_lang()
  It returns current language of message
    language message ja_JP.UTF-8
    Should g:M.get_lang() ==# 'ja'
  End
  It returns 'en' if current language is 'C'
    language message C
    Should g:M.get_lang() ==# 'en'
  End
End

Context Locale.Message.new()
  It makes a new Locale.Message object
    let m = g:M.new(s:text_path)
    Should has_key(m, 'get')
    Should has_key(m, 'load')
  End
End

Context Locale.Message.Message.get()
  language message ja_JP.UTF-8
  let m = g:M.new(s:text_path)
  It returns translated text if it exists
    Should m.get('hello') ==# 'こんにちは'
  End
  It returns original text if it doesn't exist
    Should m.get('world') ==# 'world'
  End
End

Context Locale.Message.Message._()
  language message ja_JP.UTF-8
  let m = g:M.new(s:text_path)
  It should be able to use like `get()`
    Should m._('hello') ==# 'こんにちは'
    Should m._('world') ==# 'world'
  End
End

Context Locale.Message.Message.load()
  let m = g:M.new(s:text_path)
  It loads specified language file
    call m.load('ja')
    Should m.get('hello') ==# 'こんにちは'
    call m.load('fr')
    Should m.get('hello') ==# 'ciao'
    call m.load('en')
    Should m.get('hello') ==# 'hello'
  End
End

Context Locale.Message.Message.missing()
  It should be called when the text was not found
    let m = g:M.new(s:text_path)
    call m.load('ja')
    Should m.get('world') ==# 'world'
    function! m.missing(text)
      let g:text = a:text
      return '世界'
    endfunction
    call m.load('ja')
    Should m.get('world') ==# '世界'
    Should g:text ==# 'world'
  End
End
