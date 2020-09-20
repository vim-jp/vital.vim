let s:save_cpo = &cpo
set cpo&vim

let s:_has_nvim = has('nvim')
let s:_popups = {}
let s:_id = 0

function! s:is_supported() abort
  return has('nvim') && exists('*nvim_open_win') || (!has('nvim') && exists('*popup_create') && has('patch-8.2.0286'))
endfunction

" opt = {
"   'contents': ['This', 'is', 'a', 'line'],
"   'w': 5,
"   'h': 5,
"   'x': 1,
"   'y': 1,
"   'pos': 'topleft|topright|bottomleft|bottomright|topcenter|bottomcenter',
" }
function! s:create(opt) abort
  let id = s:_nextid()
  let data = { 'winid': 0 }

  call s:_set(data, a:opt)

  if s:_has_nvim
    let data['bufnr'] = nvim_create_buf(0, 1)
    call nvim_buf_set_lines(data['bufnr'], 0, -1, 1, data['contents'])
    let data['winid'] = s:_nvim_open_win(id, data)
  else
    " neovim doesn't support scrollbar so don't enable it
    let data['winid'] = popup_create(data['contents'], {
          \ 'width': data['w'],
          \ 'height': data['h'],
          \ 'minwidth': data['w'],
          \ 'minheight': data['h'],
          \ 'maxwidth': data['w'],
          \ 'maxheight': data['h'],
          \ 'col': data['sx'],
          \ 'line': data['sy'],
          \ 'scrollbar': 0,
          \ })
    let data['bufnr'] = winbufnr(data['winid'])
  endif
  let s:_popups[id] = data
  call s:_notify(id, {}, 'create')
  return id
endfunction

function! s:close(id) abort
  if has_key(s:_popups, a:id)
    let data = s:_popups[a:id]
    if s:_has_nvim
      call nvim_win_close(data['winid'], 1)
      let data['winid'] = 0
    else
      call popup_close(data['winid'])
    endif
    call s:_notify(a:id, {}, 'close')
    call remove(s:_popups, a:id)
  endif
endfunction

function! s:_nvim_open_win(id, data) abort
  let opt = {
    \ 'relative': 'editor',
    \ 'style': 'minimal',
    \ 'width': a:data['w'],
    \ 'height': a:data['h'],
    \ 'col': a:data['sx'],
    \ 'row': a:data['sy'],
    \ 'focusable': 0,
    \ }
  return nvim_open_win(a:data['bufnr'], 1, opt)
endfunction

function! s:_set(data, opt) abort
  " copy all callbacks to data
  for [key, Cb] in items(a:opt)
    if stridx(key, 'on_') == 0
      let a:data[key] = Cb
    endif
  endfor

  " try to set values from a:opt, if not set from a:data, if not default
  let a:data['w'] = get(a:opt, 'w', get(a:data, 'w', 5))
  let a:data['h'] = get(a:opt, 'h', get(a:data, 'h', 5))

  if s:_has_nvim
    " a:opt[x/y] need to - 1
    " a:data['x/y'] already normalized
    let a:data['x'] = has_key(a:opt, 'x') ? a:opt['x'] - 1 : get(a:data, 'x', 0)
    let a:data['y'] = has_key(a:opt, 'y') ? a:opt['y'] - 1 : get(a:data, 'y', 0)
  else
    let a:data['x'] = get(a:opt, 'x', get(a:data, 'x', 1))
    let a:data['y'] = get(a:opt, 'y', get(a:data, 'y', 1))
  endif

  let a:data['contents'] = get(a:opt, 'contents', get(a:data, 'contents', []))
  let a:data['pos'] = get(a:opt, 'pos', get(a:data, 'pos', 'topleft'))

  if a:data['pos'] ==# 'topleft'
    let a:data['sx'] = a:data['x']
    let a:data['sy'] = a:data['y']
  elseif a:data['pos'] ==# 'topright'
    let a:data['sx'] = a:data['x'] + a:data['w'] + 1
    let a:data['sy'] = a:data['y']
  elseif a:data['pos'] ==# 'bottomleft'
    let a:data['sx'] = a:data['x']
    let a:data['sy'] = a:data['y'] - a:data['h'] + 1
  elseif a:data['pos'] ==# 'bottomright'
    let a:data['sx'] = a:data['x'] + a:data['w'] + 1
    let a:data['sy'] = a:data['y'] - a:data['h'] + 1
  elseif a:data['pos'] ==# 'topcenter'
    let a:data['sx'] = a:data['x'] + float2nr(a:data['x'] / 2) + 1
    let a:data['sy'] = a:data['y'] - a:data['h']
  elseif a:data['pos'] ==# 'bottomcenter'
    let a:data['sx'] = a:data['x'] + float2nr(a:data['x'] / 2) + 1
    let a:data['sy'] = a:data['y'] + 1
  else
    throw 'vital: Experimental.UI.Popup: Invalid pos'
  endif
endfunction

function! s:_nextid() abort
  let s:_id += 1
  return s:_id
endfunction

function! s:_notify(id, data, event) abort
  if has_key(s:_popups[a:id], 'on_event')
    call s:_popups[a:id]['on_event'](a:id, a:data, a:event)
  endif
  let eventhandler = 'on_' . a:event
  if has_key(s:_popups[a:id], eventhandler)
    call s:_popups[a:id][eventhandler](a:id, a:data, a:event)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttab et ai textwidth=0 fdm=marker
