let s:save_cpo = &cpo
set cpo&vim

function! s:parse(ltsv) abort
  return map(split(a:ltsv, '\r\?\n'), 's:parse_record(v:val)')
endfunction

function! s:parse_file(file) abort
  return s:parse(join(readfile(a:file), "\n"))
endfunction

function! s:parse_record(line) abort
  let record = {}
  for field in split(a:line, "\t")
    let splitted = matchlist(field, '^\([0-9A-Za-z_.-]\+\):\(.*\)$')
    if empty(splitted)
      throw 'vital: Text.LTSV: Parsing a record failed: ' . field
    endif
    let record[splitted[1]] = splitted[2]
  endfor
  return record
endfunction

function! s:dump(data) abort
  if type(a:data) == type([])
    return join(map(copy(a:data), 's:_dump_record(v:val)'), "\n")
  elseif type(a:data) == type({})
    return s:_dump_record(a:data)
  endif
  return a:data
endfunction

function! s:dump_file(data, file, ...) abort
  let ltsv = split(s:dump(a:data), "\n")
  if a:0 && a:1 && filereadable(a:file)
    let ltsv = readfile(a:file) + ltsv
  endif
  call writefile(ltsv, a:file)
endfunction

function! s:_dump_record(obj) abort
  return join(values(map(copy(a:obj), 'v:key . ":" . s:_to_s(v:val)')), "\t")
endfunction

function! s:_to_s(data) abort
  let t = type(a:data)
  return t == type('') || t == type(0) ? a:data : string(a:data)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
