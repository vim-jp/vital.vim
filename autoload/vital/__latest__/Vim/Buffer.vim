let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V)
  let s:V = a:V
  let s:P = s:V.import('Prelude')
endfunction

function! s:_vital_depends()
  return ['Prelude']
endfunction

if exists('*getcmdwintype')
  function! s:is_cmdwin()
    return getcmdwintype() !=# ''
  endfunction
else
  function! s:is_cmdwin()
    return bufname('%') ==# '[Command Line]'
  endfunction
endif

function! s:open(buffer, opener)
  let save_wildignore = &wildignore
  let &wildignore = ''
  try
    if s:P.is_funcref(a:opener)
      let loaded = !bufloaded(a:buffer)
      call a:opener(a:buffer)
    elseif a:buffer is 0 || a:buffer is ''
      let loaded = 1
      silent execute a:opener
      enew
    else
      let loaded = !bufloaded(a:buffer)
      if s:P.is_string(a:buffer)
        execute a:opener '`=a:buffer`'
      elseif s:P.is_number(a:buffer)
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

function! s:get_selected_text(...)
  echohl WarningMsg
  echom "[WARN] s:get_selected_text() is deprecated. Use 's:get_last_selected()'."
  echohl None
  return call('s:get_last_selected', a:000)
endfunction

" Get the last selected text in visual mode.
function! s:get_last_selected()
  let save = getreg('"', 1)
  let save_type = getregtype('"')
  let [begin, end] = [getpos("'<"), getpos("'>")]
  try
    if visualmode() ==# "\<C-v>"
      let begincol = begin[2] + (begin[2] ># getline('.') ? begin[3] : 0)
      let endcol   =   end[2] + (  end[2] ># getline('.') ?   end[3] : 0)
      if begincol ># endcol
        " end's col must be greater than begin.
        let tmp = begin[2:3]
        let begin[2:3] = end[2:3]
        let end[2:3] = tmp
      endif
      let virtpadchar = ' '
      let lines = map(getline(begin[1], end[1]), '
      \ (v:val[begincol-1 : endcol-1])
      \ . repeat(virtpadchar, endcol-len(v:val))
      \')
    else
      if begin[1] ==# end[1]
        let lines = [getline(begin[1])[begin[2]-1 : end[2]-1]]
      else
        let lines = [getline(begin[1])[begin[2]-1 :]]
        \         + (end[1] - begin[1] <# 2 ? [] : getline(begin[1]+1, end[1]-1))
        \         + [getline(end[1])[: end[2]-1]]
      endif
    endif
    return join(lines, "\n") . (visualmode() ==# "V" ? "\n" : "")
  finally
    call setreg('"', save, save_type)
  endtry
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
