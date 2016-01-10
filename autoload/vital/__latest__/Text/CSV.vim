let s:save_cpo = &cpo
set cpo&vim

function! s:parse(csvlines) abort
  return map(split(a:csvlines, '\r\?\n', 1), 's:parse_record(v:val)')
endfunction

function! s:parse_file(file) abort
  return s:parse(join(readfile(a:file), "\n"))
endfunction

function! s:parse_record(csvline) abort
  let csvline = a:csvline
  let record = []
  let rx_rest = '\(,\|$\)\(.*\)'
  let rx_quotecol = '^"\(\|\%(.\{-}"\@<!\)\?\%(""\)*\)"' . rx_rest
  let rx_nonquotecol = '^\([^,]*\)' . rx_rest
  while csvline !=# ''
    if csvline[0] ==# '"'
      let m = matchlist(csvline, rx_quotecol)
    else
      let m = matchlist(csvline, rx_nonquotecol)
      if m[1] =~# '[",]'
        throw 'vital: Text.CSV: [",] must be wrapped by double-quotes: ' . csvline
      endif
    endif
    if empty(m)
      throw 'vital: Text.CSV: Parsing a record failed: ' . csvline
    endif
    if csvline[0] ==# '"'
      if m[1] =~# '\%("\)\@<!"\%(""\)*\%("\)\@!'
        throw 'vital: Text.CSV: Parsing a record failed: ' . csvline
      endif
      let m[1] = substitute(m[1], '""', '"', 'g')
    endif
    call add(record, m[1])
    if m[2] ==# ',' && m[3] ==# ''
        call add(record, '')
    endif
    let csvline = m[3]
  endwhile
  return record
endfunction

function! s:dump(records) abort
  if type(a:records) is type([])
    return join(map(copy(a:records), 's:dump_record(v:val)'), "\n")
  else
    throw 'vital: Text.CSV: dump(): Argument is not List.'
  endif
endfunction

function! s:dump_file(records, file, ...) abort
  let csv = split(s:dump(a:records), '\n', 1)
  if a:0 && a:1 && filereadable(a:file)
    let csv = readfile(a:file) + csv
  endif
  call writefile(csv, a:file)
endfunction

function! s:dump_record(record) abort
  if type(a:record) is type([])
    return join(map(copy(a:record), 's:_to_s(v:val)'), ',')
  else
    throw 'vital: Text.CSV: dump_record(): Argument is not List.'
  endif
endfunction

" TODO: More customizable?
function! s:_to_s(data) abort
  let t = type(a:data)
  if t is type('')
    if a:data =~# '[",\r\n]'
      return '"' . substitute(a:data, '"', '""', 'g') . '"'
    else
      return a:data
    endif
  elseif t is type(0)
    return a:data
  else
    return string(a:data)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
