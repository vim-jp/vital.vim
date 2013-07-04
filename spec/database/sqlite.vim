source spec/base.vim
scriptencoding utf-8

let g:S = vital#of('vital').import('Database.SQLite')

Context Database.is_available()
  It is true if you have sqlite3 command
    Should executable('sqlite3') ==# g:S.is_available()
  End
End
