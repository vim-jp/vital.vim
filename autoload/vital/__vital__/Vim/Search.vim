let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:S = a:V.import('Data.String')
endfunction

function! s:_vital_depends() abort
  return ['Data.String']
endfunction

" [I wrapper
" known issue: it messes undo tree slightly
function! s:finddef(str) abort
  let before = getpos('.')
  call append(0, a:str) " ugh
  try
    " call setpos('.', getpos('1'))
    1
    redir => result
      silent! normal! [I
    redir END

    " tokenizing phase
    let lines = s:S.lines(result)
    let tokens = []
    for line in lines
      if line =~# '^\s*\d'
        let matches = matchlist(line, '\s*\d\+:\s\+\(\d\+\)\(.*\)')
        let lnum = matches[1]
        let body = matches[2]
        let tokens += [['item', lnum, body]]
      else
        let tokens += [['file', line]]
      endif
    endfor

    " parsing phase
    let parsed = {}
    let current_file = '*undefined*'
    for [label ; xs] in tokens
      if label ==# 'file' || current_file ==# '*undefined*'
        let current_file = xs[0]
        let parsed[current_file] = {}
      else
        let parsed[current_file][xs[0]] = xs[1]
      endif
    endfor
    return parsed
  finally
    silent! undo
    call setpos('.', before)
  endtry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
