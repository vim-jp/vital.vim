let s:save_cpo = &cpo
set cpo&vim

"
" Flow Layout
"
let s:flow_layout = {}

function! s:new() abort
  return deepcopy(s:flow_layout)
endfunction

function! s:_flow_layout_apply(wl, data) dict abort
  " already exists a window
  let items = copy(a:data.items)
  let skip = 1

  for item in items
    if !skip
      botright vsplit
    endif

    if has_key(item, 'bufref')
      call a:wl.bufopen(item.bufref)
    endif
    if has_key(item, 'walias')
      call a:wl.walias('.', item.walias)
    endif

    let skip = 0
  endfor
endfunction
let s:flow_layout.apply = function('s:_flow_layout_apply')

" @vimlint(EVL103, 1, a:wl)
" @vimlint(EVL103, 1, a:data)
function! s:_flow_layout_adjust_size(wl, data) dict abort
  " do nothing
endfunction
" @vimlint(EVL103, 0, a:wl)
" @vimlint(EVL103, 0, a:data)
let s:flow_layout.adjust_size = function('s:_flow_layout_adjust_size')

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: tabstop=2 shiftwidth=2 expandtab
