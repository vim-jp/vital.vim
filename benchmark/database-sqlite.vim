" 1. make sure you don't have a.db on the current dir
" 2. run this (quickrun is handy)
" 3. remove a.db later on
let s:S = vital#of('vital').import('Database.Sqlite')
call s:S.debug_mode_to(0)
let t = reltime()
call s:S.query_rawdata(
      \ 'a.db',
      \ 'CREATE TABLE people (id int, friend int);')
call s:S.query_rawdata(
      \ 'a.db',
      \ 'CREATE INDEX _id ON people (id);')
let query = ''
for i in range(0, 999)
  let query .= printf(
        \ 'INSERT INTO people VALUES (%s, %s);',
        \ i, i + 1 % 1000)
endfor
call s:S.query_rawdata('a.db', query)
let i = 1
while i != 1
  let i = s:S.query(
        \ 'a.db',
        \ 'SELECT * FROM cities WHERE id = ?;',
        \ 1)[0]['friend']
endwhile
echo reltimestr(reltime(t))
" at ddb533883482bdd8a2735acbd95f4cd32e26047e
" this was  19.225146sec on ujihisa's computer (zenbook/gentoo/ssd/i5)
