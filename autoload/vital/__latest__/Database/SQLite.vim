let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V)
  let s:V = a:V
  let s:P = s:V.import('Process')
endfunction

function! s:_vital_depends()
  return ['Process']
endfunction

let s:_debug_mode = 0

function! s:is_available()
  return executable('sqlite3')
endfunction

function! s:_quote_escape(x)
  return printf('"%s"', escape(a:x, '"'))
endfunction

" This function name is long on purpose to discourage people to use that
" frequently.
function! s:build_line_from_query_with_placeholders(q, xs)
  let num_placeholders = len(split(a:q, '?', 1)) - 1
  call s:debug('build_line_from_query_with_placeholders', a:q, a:xs,
        \ {'num_placeholders': num_placeholders})
  if len(a:xs) != num_placeholders
    throw "Database.SQLite.build_line_from_query_with_placeholders() number of placeholders doesn't match."
  endif
  let line = substitute(a:q, '?', '%s', 'g')
  if num_placeholders > 0
    let line = call('printf', [line] + map(copy(a:xs), 's:_quote_escape(v:val)'))
  endif
  return line
endfunction

" s:query('a.db', 'SELECT * from b') ==
"   s:query('a.db', 'SELECT * from b', [])
function! s:query_rawdata(db, q, ...)
  if a:0 > 1
    throw 'Database.SQLite.query() too many arguments'
  endif
  let xs = get(a:000, 0, [])
  " hmm...
  " if !filewritable(a:db)
  "   throw printf("Database.SQLite.query() given db (%s) isn't writable.", a:db)
  " endif
  let built = s:build_line_from_query_with_placeholders(a:q, xs)
  let cmd = printf(
        \ 'sqlite3 -batch -line %s',
        \ s:_quote_escape(a:db))
  call s:debug('query', a:q, xs,
        \ {'built': built, 'cmd': cmd})
  return s:P.system(cmd, built)
endfunction

" '
"    x = 123a
"
"    x = 999'
" to [{'x':'123a'},{'x','999}]
function! s:_to_vim(result)
  let chunks = split(a:result, "\r\\?\n\r\\?\n")
  call s:debug('parse_result', a:result, chunks)
  let l = []
  for chunk in chunks
    let d = {}
    for line in split(chunk, "\r\\?\n")
      let tmp = matchlist(line, '^\s*\(\w\+\) = \(.*\)$')
      call s:debug(tmp)
      if len(tmp) > 3
        let d[tmp[1]] = tmp[2]
      endif
    endfor
    call add(l, d)
  endfor
  return l
endfunction

" s:query('a.db', 'SELECT * from b') ==
"   s:query('a.db', 'SELECT * from b', [])
function! s:query(db, q, ...)
  if a:0 > 1
    throw 'Database.SQLite.query() too many arguments'
  endif
  let xs = get(a:000, 0, [])
  return s:_to_vim(s:query_rawdata(a:db, a:q, xs))
endfunction

function! s:debug_mode_to(to)
  let s:_debug_mode = a:to
endfunction

function! s:debug(...)
  if s:_debug_mode
    echomsg string(a:000)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
