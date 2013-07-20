let &runtimepath = expand('<sfile>:h:h')
if exists('g:vimproc_path')
	let &runtimepath .= ',' . g:vimproc_path
endif

let s:results = {}
let s:context_stack = []

function! s:should(cond, result)
  " FIXME: validate
  let it = s:context_stack[-1][1]
  let context = s:context_stack[-2][1]
  if !has_key(s:results, context)
    let s:results[context] = []
  endif
  call add(s:results[context], a:result ? '.' :
        \ printf('It %s : %s', it, a:cond))
endfunction

function! s:_should(it, cond)
  echo a:cond
  echo eval(a:cond)
  return eval(a:cond) ? '.' : a:it
endfunction

function! s:shouldthrow(args)
	let expr = matchstr(a:args, '\zs.*\ze,\s*/.*/')
	try
		call eval(expr)
		call s:should(a:args, 0)
	catch
		let exp = matchstr(a:args, '.*,\s*/\zs.*\ze/\s*')
		call s:should(a:args, v:exception =~# exp)
	endtry
endfunction


" after example:
"
" [.] Prelude.is_windows()
" [F] Prelude.is_numeric()
"
" Failure
"   Prelude.is_numeric()
"     - It checks if the argument is a numeric : g:V.is_numeric([]) ==# 1
"
function! s:_format_results(results)
  let messages = []

  " {'Prelude.truncate_smart()': ['.', '.', 'It xxx']}
  "   -> {'Prelude.truncate_smart()': ['It xxx']}
  let summary_results = map(copy(a:results), "filter(v:val, 'v:val !=# \".\"')")

  for results in items(summary_results)
    let mark = empty(results[1]) ? '[.] ' : '[F] '
    call add(messages, mark . results[0])
    unlet results
  endfor

  call add(messages, '')

  " TODO dirty
  let init = 1
  for results in items(summary_results)
    if !empty(results[1])
      if init
        call add(messages, 'Failure')
        let init = 0
      endif

      call add(messages, '  ' . results[0])
      for fail_message in results[1]
        call add(messages, '    - ' . fail_message)
      endfor
      call add(messages, '')
    endif
    unlet results
  endfor

  return messages
endfunction

function! s:_update_file(lines, filename)
  call writefile(extend(readfile(a:filename), a:lines), a:filename)
endfunction

command! -nargs=+ Context
      \ call add(s:context_stack, ['c', <q-args>])
command! -nargs=+ It
      \ call add(s:context_stack, ['i', <q-args>])
command! -nargs=+ Should
      \ call s:should(<q-args>, eval(<q-args>))
command! -nargs=+ ShouldThrow call s:shouldthrow(<q-args>)
command! -nargs=0 End
      \ call remove(s:context_stack, -1) |
      \ redraw!

command! -nargs=+ Fin
      \ call writefile([string(s:results)], <q-args>) |
      \ qa!
command! -nargs=+ FinUpdate
      \ call s:_update_file(s:_format_results(s:results), <q-args>) |
      \ qa!
