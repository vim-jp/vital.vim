let s:save_cpo = &cpo
set cpo&vim

"
" Grid Layout
"
let s:grid_layout = {}

function! s:new() abort
  return deepcopy(s:grid_layout)
endfunction

function! s:_grid_layout_apply(wl, data) dict abort
  let nrows = float2nr(ceil(len(a:data.cells) / (1.0 * a:data.column)))
  " already exists a row window
  for _ in range(2, nrows)
    aboveleft split
  endfor

  " col starts with 1, since already exists a column window
  let [col, row] = [1, 0]
  while row <= nrows && (col + a:data.column * row) < len(a:data.cells)
    call s:_apply_common_options(a:wl, get(a:data.cells, col + a:data.column * row - 1, {}))

    belowright vsplit
    let col += 1

    if col >= a:data.column
      call s:_apply_common_options(a:wl, get(a:data.cells, col + a:data.column * row - 1, {}))

      execute 'wincmd j'
      let col = 1
      let row += 1
    endif
  endwhile
endfunction
let s:grid_layout.apply = function('s:_grid_layout_apply')

function! s:_apply_common_options(wl, layoutdata) abort
  " open buffer
  if has_key(a:layoutdata, 'bufref')
    call a:wl.bufopen(a:layoutdata.bufref)
  endif
  " make walias
  if has_key(a:layoutdata, 'walias')
    call a:wl.walias('.', a:layoutdata.walias)
  endif
endfunction

" @vimlint(EVL103, 1, a:wl)
" @vimlint(EVL103, 1, a:data)
function! s:_grid_layout_adjust_size(wl, data) dict abort
  " do nothing
endfunction
" @vimlint(EVL103, 0, a:wl)
" @vimlint(EVL103, 0, a:data)
let s:grid_layout.adjust_size = function('s:_grid_layout_adjust_size')

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: tabstop=2 shiftwidth=2 expandtab
