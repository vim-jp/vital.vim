let s:save_cpo = &cpo
set cpo&vim

"
" Grid Layout
"
let s:grid_layout = {}

function! s:new() abort
  return deepcopy(s:grid_layout)
endfunction

" @vimlint(EVL103, 1, a:wl)
function! s:_grid_layout_apply(wl, data) dict abort
  let nrows = float2nr(ceil(len(a:data.cells) / (1.0 * a:data.column)))
  " already exists a row window
  for _ in range(2, nrows)
    aboveleft split
  endfor

  " already exists a column window
  let [col, row] = [1, 0]
  while row <= nrows && (col + a:data.column * row) < len(a:data.cells)
    belowright vsplit
    let col += 1

    if col >= a:data.column
      execute 'wincmd j'
      let col = 1
      let row += 1
    endif
  endwhile
endfunction
" @vimlint(EVL103, 0, a:wl)
let s:grid_layout.apply = function('s:_grid_layout_apply')

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
