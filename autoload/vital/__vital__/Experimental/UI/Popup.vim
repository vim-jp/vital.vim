let s:save_cpo = &cpo
set cpo&vim

let s:_has_nvim = has('nvim')
let s:_popups = {}

function! s:is_supported() abort
  return has('nvim') && exists('*nvim_open_win') || (!has('nvim') && exists('*popup_create') && has('patch-8.2.0286'))
endfunction

" opt = {
"   'contents': ['This', 'is', 'a', 'line'],
"   'w': 5,
"   'h': 5,
"   'x': 1,
"   'y': 1,
" }
function! s:create(opt) abort
  let data = {}
  call s:_set_w(data, get(a:opt, 'w', 5))
  call s:_set_h(data, get(a:opt, 'h', 5))
  call s:_set_contents(data, get(a:opt, 'contents', []))
  call s:_set_x(data, get(a:opt, 'x', 1))
  call s:_set_y(data, get(a:opt, 'y', 1))

  if s:_has_nvim
    let buf = nvim_create_buf(0, 1)
    call nvim_buf_set_lines(buf, 0, -1, 1, s:_get_contents(data))
    let opt = {
          \ 'relative': 'editor',
          \ 'style': 'minimal',
          \ 'width': data['w'],
          \ 'height': data['h'],
          \ 'col': data['x'],
          \ 'row': data['y'],
          \ 'focusable': 0,
          \ }
    let id = nvim_open_win(buf, 1, opt)
  else
    " neovim doesn't support scrollbar so don't enable it
    let id = popup_create(s:_get_contents(data), {
          \ 'width': data['w'],
          \ 'height': data['h'],
          \ 'minwidth': data['w'],
          \ 'minheight': data['h'],
          \ 'maxwidth': data['w'],
          \ 'maxheight': data['h'],
          \ 'col': data['x'],
          \ 'line': data['y'],
          \ 'scrollbar': 0,
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

function! s:_set_w(data, w) abort
  let a:data['w'] = a:w
endfunction

function! s:_set_h(data, h) abort
  let a:data['h'] = a:h
endfunction

function! s:_set_y(data, y) abort
  if s:_has_nvim
    let a:data['y'] = a:y - 1
  else
    let a:data['y'] = a:y
  endif
endfunction

function! s:_set_x(data, x) abort
  if s:_has_nvim
    let a:data['x'] = a:x - 1
  else
    let a:data['x'] = a:x
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
