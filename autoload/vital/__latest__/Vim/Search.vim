let s:save_cpo = &cpo
set cpo&vim

" [I wrapper
function! s:finddef(pos)
  let before = getpos('.')
  try
    call setpos('.', a:pos)
    redir => result
      normal! [I
    redir END

    " tokenizing phase
    let lines = s:lines(result)
    let tokens = []
    for line in lines
      if line =~ '^\s'
        let [_, lnum, body ; _2] = matchlist(line, '\s\+\d\+:\s\+\(\d\+\)\(.*\)')
        let tokens += [['item', lnum, body]]
      else
        let tokens += [['file', line]]
      endif
    endfor

    " parsing phase
    let parsed = {}
    let current_file = '*undefined*'
    for [label ; xs] in tokens
      if label ==# 'file'
        let current_file = xs[0]
        let parsed[current_file] = {}
      else
        let parsed[current_file][xs[0]] = xs[1]
      endif
    endfor
    return parsed
  finally
    call setpos('.', before)
  endtry
endfunction

" just for now
" TODO move this to Data.String
function! s:lines(str)
  return split(a:str, '\r\?\n')
endfunction

echo s:finddef(getpos('.'))

let &cpo = s:save_cpo
unlet s:save_cpo
