source spec/base.vim

let g:URI = vital#of('vital').import('Web.URI')

Context Web.URI.new('http://twitter.com/tyru')
  It is my twitter URL, oh you already knew it?
    let uri = g:URI.new('http://twitter.com/tyru')
    Should uri.scheme() ==# 'http'
    Should uri.host() ==# 'twitter.com'
    Should uri.path() ==# '/tyru'
    Should uri.opaque() ==# '//twitter.com/tyru'
    Should uri.fragment() ==# ''
    Should uri.to_string() ==# 'http://twitter.com/tyru'
  End

  It is personal space however I'm trying to change the URL
    let uri = g:URI.new('http://twitter.com/tyru')
    call uri.scheme('ftp')
    Should uri.scheme() ==# 'ftp'
    Should uri.to_string() ==# 'ftp://twitter.com/tyru'
    call uri.host('ftp.vim.org')
    Should uri.host() ==# 'ftp.vim.org'
    Should uri.to_string() ==# 'ftp://ftp.vim.org/tyru'
    call uri.path('pub/vim/unix/vim-7.3.tar.bz2')
    Should uri.path() ==# '/pub/vim/unix/vim-7.3.tar.bz2'
    Should uri.to_string() ==# 'ftp://ftp.vim.org/pub/vim/unix/vim-7.3.tar.bz2'
    call uri.path('/pub/vim/unix/vim-7.3.tar.bz2')
    " uri.path() ignores head slashes.
    Should uri.path() ==# '/pub/vim/unix/vim-7.3.tar.bz2'
    Should uri.to_string() ==# 'ftp://ftp.vim.org/pub/vim/unix/vim-7.3.tar.bz2'
  End
End

Context Web.URI.new('http://d.hatena.ne.jp/tyru/20100619/git_push_vim_plugins_to_github#c')
  It is my blog's entry, oh you (ry
    let uri = g:URI.new('http://d.hatena.ne.jp/tyru/20100619/git_push_vim_plugins_to_github#c')
    Should uri.scheme() ==# 'http'
    Should uri.host() ==# 'd.hatena.ne.jp'
    Should uri.path() ==# '/tyru/20100619/git_push_vim_plugins_to_github'
    Should uri.opaque() ==# '//d.hatena.ne.jp/tyru/20100619/git_push_vim_plugins_to_github'
    Should uri.fragment() ==# 'c'
    Should uri.to_string() ==# 'http://d.hatena.ne.jp/tyru/20100619/git_push_vim_plugins_to_github#c'
  End

  It is my blog's entry but I don't care changing the URL
    call uri.scheme('https')
    Should uri.scheme() ==# 'https'
    Should uri.to_string() ==# 'https://d.hatena.ne.jp/tyru/20100619/git_push_vim_plugins_to_github#c'
    call uri.host('github.com')
    Should uri.host() ==# 'github.com'
    Should uri.to_string() ==# 'https://github.com/tyru/20100619/git_push_vim_plugins_to_github#c'
    call uri.path('tyru/urilib.vim/blob/master/autoload/urilib.vim')
    Should uri.path() ==# '/tyru/urilib.vim/blob/master/autoload/urilib.vim'
    Should uri.to_string() ==# 'https://github.com/tyru/urilib.vim/blob/master/autoload/urilib.vim#c'
    call uri.fragment('L32')
    Should uri.fragment() ==# 'L32'
    Should uri.to_string() ==# 'https://github.com/tyru/urilib.vim/blob/master/autoload/urilib.vim#L32'
    call uri.fragment('#L32')
    " uri.fragment({fragment}) ignores head # characters.
    Should uri.fragment() ==# 'L32'
    Should uri.to_string() ==# 'https://github.com/tyru/urilib.vim/blob/master/autoload/urilib.vim#L32'
  End
End

Context URI.is_uri({uri})
  It detects {uri} is URI or not
    Should g:URI.is_uri('http://twitter.com/tyru')
    Should g:URI.is_uri('http://d.hatena.ne.jp/tyru/20100619/git_push_vim_plugins_to_github#c')
    Should ! g:URI.is_uri('foo')
    Should ! g:URI.is_uri('/bar')
    Should g:URI.is_uri('file://baz/')
    Should g:URI.is_uri('file:///home/tyru/')
    Should g:URI.is_uri('file:///home/tyru')
    Should g:URI.is_uri('ftp://withoutslash.com')
  End
End


" vim:set et ts=2 sts=2 sw=2 tw=0:
