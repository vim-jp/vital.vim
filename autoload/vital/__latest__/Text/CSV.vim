let s:save_cpo = &cpo
set cpo&vim

function! s:parse(csv)
  return map(split(a:csv, '\r\?\n'), 's:parse_record(v:val)')
endfunction

function! s:parse_file(file)
  return s:parse(join(readfile(a:file), "\n"))
endfunction

function! s:parse_record(line)
  let line = a:line
  let records = []
  let rx_rest = '\(,\|$\)\(.*\)'
  let rx_quotecol = '^"\(\|\%(.\{-}"\@<!\)\?\%(""\)*\)"' . rx_rest
  let rx_nonquotecol = '^\([^,]*\)' . rx_rest
  while line !=# ''
    if line[0] ==# '"'
      let m = matchlist(line, rx_quotecol)
    else
      let m = matchlist(line, rx_nonquotecol)
      if m[1] =~# '[",]'
        throw 'vital: Text.CSV: [",] must be wrapped by double-quotes: ' . line
      endif
    endif
    if empty(m)
      throw 'vital: Text.CSV: Parsing a record failed: ' . line
    endif
    if line[0] ==# '"'
      if m[1] =~# '\%("\)\@<!"\%(""\)*\%("\)\@!'
        throw 'vital: Text.CSV: Parsing a record failed: ' . line
      endif
      let m[1] = substitute(m[1], '""', '"', 'g')
    endif
    call add(records, m[1])
    if m[2] ==# ',' && m[3] ==# ''
        call add(records, '')
    endif
    let line = m[3]
  endwhile
  return records
endfunction

function! s:dump(data)
  if type(a:data) is type([])
    return join(map(copy(a:data), 's:_dump_record(v:val)'), "\n")
  endif
  return a:data
endfunction

function! s:dump_file(data, file, ...)
  let csv = split(s:dump(a:data), "\n")
  if a:0 && a:1 && filereadable(a:file)
    let csv = readfile(a:file) + csv
  endif
  call writefile(csv, a:file)
endfunction

function! s:_dump_record(obj)
  return join(values(map(copy(a:obj), 's:_to_s(v:val)')), "\t")
endfunction

" TODO: More customizable?
function! s:_to_s(data)
  let t = type(a:data)
  if t is type('')
    if a:data =~# '"'
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
