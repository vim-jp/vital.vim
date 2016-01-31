let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:P = s:V.import('Prelude')
  let s:G = s:V.import('Vim.Guard')
endfunction

function! s:_vital_depends() abort
  return ['Prelude', 'Vim.Guard']
endfunction

if exists('*getcmdwintype')
  function! s:is_cmdwin() abort
    return getcmdwintype() !=# ''
  endfunction
else
  function! s:is_cmdwin() abort
    return bufname('%') ==# '[Command Line]'
  endfunction
endif

function! s:open(buffer, opener) abort
  let save_wildignore = &wildignore
  let &wildignore = ''
  try
    if s:P.is_funcref(a:opener)
      let loaded = !bufloaded(a:buffer)
      call a:opener(a:buffer)
    elseif a:buffer is 0 || a:buffer is# ''
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

function! s:get_selected_text(...) abort
  echohl WarningMsg
  echom "[WARN] s:get_selected_text() is deprecated. Use 's:get_last_selected()'."
  echohl None
  return call('s:get_last_selected', a:000)
endfunction

" Get the last selected text in visual mode
" without using |gv| to avoid |textlock|.
" NOTE:
" * This function uses |gv| only when using |CTRL-V|
"   because |gv| is the only way to get selected text
"   when using <C-v>$ .
"   Please see #192 for the details.
" * If you don't care about |textlock|,
"   you can use simple version of this function.
"   https://github.com/vim-jp/vital.vim/commit/39aae80f3839fdbeebd838ff14d87327a6b889a9
function! s:get_last_selected() abort
  if visualmode() ==# "\<C-v>"
    let save = getreg('"', 1)
    let save_type = getregtype('"')
    try
      normal! gv""y
      return @"
    finally
      call setreg('"', save, save_type)
    endtry
  else
    let [begin, end] = [getpos("'<"), getpos("'>")]
    let lastchar = matchstr(getline(end[1])[end[2]-1 :], '.')
    if begin[1] ==# end[1]
      let lines = [getline(begin[1])[begin[2]-1 : end[2]-2]]
    else
      let lines = [getline(begin[1])[begin[2]-1 :]]
      \         + (end[1] - begin[1] <# 2 ? [] : getline(begin[1]+1, end[1]-1))
      \         + [getline(end[1])[: end[2]-2]]
    endif
    return join(lines, "\n") . lastchar . (visualmode() ==# 'V' ? "\n" : '')
  endif
endfunction

function! s:read_content(content, ...) abort
  let options = extend({
        \ 'tempfile': '',
        \ 'fileformat': '',
        \ 'encoding': '',
        \ 'binary': 0,
        \ 'nobinary': 0,
        \ 'bad': '',
        \ 'edit': 0,
        \}, get(a:000, 0, {}))
  let tempfile = empty(options.tempfile) ? tempname() : options.tempfile
  let optnames = [
        \ empty(options.fileformat) ? '' : '++ff=' . options.fileformat,
        \ empty(options.encoding) ? '' : '++enc=' . options.encoding,
        \ empty(options.binary) ? '' : '++bin',
        \ empty(options.nobinary) ? '' : '++nobin',
        \ empty(options.bad) ? '' : '++bad=' . options.bad,
        \ empty(options.edit) ? '' : '++edit',
        \]
  let optname = join(filter(optnames, '!empty(v:val)'))
  try
    call writefile(a:content, tempfile)
    execute printf('keepalt keepjumps read %s%s',
          \ empty(optname) ? '' : optname . ' ',
          \ fnameescape(tempfile),
          \)
  finally
    call delete(tempfile)
  endtry
endfunction

function! s:edit_content(content, ...) abort
  let options = extend({
        \ 'edit': 1,
        \}, get(a:000, 0, {}))
  let guard = s:G.store('&l:modifiable')
  let saved_view = winsaveview()
  try
    let &l:modifiable=1
    silent keepjumps %delete _
    silent call s:read_content(a:content, options)
    silent keepjumps 1delete _
  finally
    keepjump call winrestview(saved_view)
    call guard.restore()
  endtry
  setlocal nomodified
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
