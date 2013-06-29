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
let query = 'BEGIN TRANSACTION;'
for i in range(0, 999)
  let query .= printf(
        \ 'INSERT INTO people VALUES (%s, %s);',
        \ i, (i + 1) % 1000)
endfor
let query .= 'COMMIT;'
call s:S.query_rawdata('a.db', query)
let i = 1
while i != 0
  let i = s:S.query(
        \ 'a.db',
        \ 'SELECT * FROM people WHERE id = ?;',
        \ [i])[0]['friend']
endwhile
echo reltimestr(reltime(t))
" at 6932db78d9cfa7136bf35bb6919675fa078f5097
" this was 40.749305sec on ujihisa's computer (zenbook/gentoo/ssd/i5)
