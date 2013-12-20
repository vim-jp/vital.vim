let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V)
  let s:V = a:V
endfunction

function! s:is_cmdwin()
  return bufname('%') ==# '[Command Line]'
endfunction

function! s:open(buffer, opener)
  let save_wildignore = &wildignore
  let &wildignore = ''
  try
    if s:V.is_funcref(a:opener)
      let loaded = !bufloaded(a:buffer)
      call a:opener(a:buffer)
    elseif a:buffer is 0 || a:buffer is ''
      let loaded = 1
      silent execute a:opener
      enew
    else
      let loaded = !bufloaded(a:buffer)
      if s:V.is_string(a:buffer)
        execute a:opener '`=a:buffer`'
      elseif s:V.is_number(a:buffer)
        silent execute a:opener
        execute a:buffer 'buffer'
      else
        throw 'vital: Vim.Buffer: Unknown opener type.'
      endif
    endif
  finally
    let &wildignore = save_wildignore
  endtry
  return loaded
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
