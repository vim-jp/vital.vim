let s:save_cpo = &cpo
set cpo&vim

let s:_has_nvim = has('nvim')
let s:_popups = {}

function! s:is_supported() abort
  return has('nvim') && exists('*nvim_open_win') || !has('nvim') && exists('*popup_create')
endfunction

" opt = {
"   'contents': ['This', 'is', 'a', 'line'],
"   'width': 5,
"   'height': 5,
"   'line': 1,
"   'col': 1,
" }
function! s:create(opt) abort
  let data = {}
  call s:_set_width(data, get(a:opt, 'width', 5))
  call s:_set_height(data, get(a:opt, 'height', 5))
  call s:_set_contents(data, get(a:opt, 'contents', []))
  call s:_set_line(data, get(a:opt, 'line', 1))
  call s:_set_col(data, get(a:opt, 'col', 1))
  if s:_has_nvim
    let buf = nvim_create_buf(0, 1)
    call nvim_buf_set_lines(buf, 0, -1, 1, s:_get_contents(data))
    let opt = {
          \ 'relative': 'editor',
          \ 'style': 'minimal',
          \ 'width': data['width'],
          \ 'height': data['height'],
          \ 'row': data['line'],
          \ 'col': data['col'],
          \ 'focusable': 0,
          \ }
    let id = nvim_open_win(buf, 1, opt)
  else
    let id = popup_create(s:_get_contents(data), {
          \ 'width': data['width'],
          \ 'height': data['height'],
          \ 'minwidth': data['width'],
          \ 'minheight': data['height'],
          \ 'maxwidth': data['width'],
          \ 'maxheight': data['height'],
          \ 'line': data['line'],
          \ 'col': data['col'],
          \ })
  endif
  let s:_popups[id] = data
  return id
endfunction

function! s:_set_contents(data, contents) abort
  let a:data['contents'] = a:contents
endfunction

function! s:_get_contents(data) abort
  return get(a:data, 'contents', [])
endfunction

function! s:_set_width(data, width) abort
  let a:data['width'] = a:width
endfunction

function! s:_get_width(data) abort
  return a:data['width']
endfunction

function! s:_get_height(data) abort
  return a:data['height']
endfunction

function! s:_set_height(data, height) abort
  let a:data['height'] = a:height
endfunction

function! s:_set_line(data, line) abort
  if s:_has_nvim
    let a:data['line'] = a:line - 1
  else
    let a:data['line'] = a:line
  endif
endfunction

function! s:_set_col(data, col) abort
  if s:_has_nvim
    let a:data['col'] = a:col - 1
  else
    let a:data['col'] = a:col
  endif
endfunction

function! s:close(id) abort
  if has_key(s:_popups, a:id)
    if s:_has_nvim
      silent! call nvim_win_close(a:id, 1)
    else
      silent! call popup_close(a:id)
    endif
    call remove(s:_popups, a:id)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttab et ai textwidth=0 fdm=marker
