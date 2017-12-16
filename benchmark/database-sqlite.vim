" 1. make sure you don't have a.db on the current dir
" 2. run this (quickrun is handy)
" 3. remove a.db later on
let s:S = vital#vital#new().import('Database.SQLite')
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
" at e5b00de9a49106cffaefa90184b75cded2ca0a77
" this was 26.262517 on ujihisa's computer (zenbook/gentoo/ssd/i5)
" at b6a03fbc685bb789bf5afe2fe8c7bb0ddaa0cea6
" this was 14.648742 on ujihisa's zenbook gentoo. thanks ichigok!
" this was 11.648742 on ujihisa's mbr gentoo. thanks ichigok!
