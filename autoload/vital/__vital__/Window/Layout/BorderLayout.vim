let s:save_cpo = &cpo
set cpo&vim

"
" Border Layout
"
" +----------------------+
" |        north         |
" +------+--------+------+
" | west | center | east |
" +------+--------+------+
" |        south         |
" +----------------------+
"
" north.width = south.width = west.width + center.width + east.width
" north.height + south.height + center.height = parent.height
"
let s:border_layout = {
\ '__size_list': [],
\}

function! s:new() abort
  return deepcopy(s:border_layout)
endfunction

" function! s:border_layout.validate_layout_data(wl, data, workbuf) abort
"   for region in ['north', 'south', 'west', 'center', 'east']
"     if has_key(a:data, region)
"       call a:wl.validate_layout_data(a:data[region], a:workbuf)
"     endif
"   endfor
" endfunction

function! s:_border_layout_apply(wl, data) dict abort
  " adjust
  if !has_key(a:data, 'center')
    if has_key(a:data, 'west')
      let a:data.center = a:data.west
      unlet a:data.west
    elseif has_key(a:data, 'east')
      let a:data.center = a:data.east
      unlet a:data.east
    elseif has_key(a:data, 'north')
      let a:data.center = a:data.north
      unlet a:data.north
    elseif has_key(a:data, 'south')
      let a:data.center = a:data.south
      unlet a:data.south
    endif
  endif

  " split vertical
  let openers = []
  if has_key(a:data, 'north')
    let openers += [s:_make_opener(self, 'aboveleft split', a:data.north)]
  endif
  if has_key(a:data, 'south')
    let openers += [s:_make_opener(self, 'belowright split', a:data.south)]
  endif

  " split horizontal
  if has_key(a:data, 'east')
    let openers += [s:_make_opener(self, 'belowright vsplit', a:data.east)]
  endif
  if has_key(a:data, 'west')
    let openers += [s:_make_opener(self, 'aboveleft vsplit', a:data.west)]
  endif
  if has_key(a:data, 'center')
    let openers += [s:_make_opener(self, '', a:data.center)]
  endif

  let prev_winvar = getwinvar('.', '')
  let winsize = {'width': winwidth('.'), 'height': winheight('.')}
  " do layout
  for opener in openers
    let winvar = getwinvar('.', '')
    call opener.apply(a:wl, winsize)
    for nr in range(1, winnr('$'))
      if getwinvar(nr, '') is winvar
        execute nr 'wincmd w'
        break
      endif
    endfor
  endfor

  for nr in range(1, winnr('$'))
    if getwinvar(nr, '') is prev_winvar
      execute nr 'wincmd w'
      break
    endif
  endfor
endfunction
let s:border_layout.apply = function('s:_border_layout_apply')

" @vimlint(EVL103, 1, a:wl)
" @vimlint(EVL103, 1, a:data)
function! s:_border_layout_adjust_size(wl, data) dict abort
  " adjust size
  let winvar = getwinvar('.', '')
  for size in self.__size_list
    for nr in range(1, winnr('$'))
      if getwinvar(nr, '') is size.winvar
        execute nr 'wincmd w'
        if has_key(size, 'width')
          execute 'vertical resize' size.width
        endif
        if has_key(size, 'height')
          execute 'resize' size.height
        endif
        break
      endif
    endfor
  endfor

  for nr in range(1, winnr('$'))
    if getwinvar(nr, '') is winvar
      execute nr 'wincmd w'
      break
    endif
  endfor
endfunction
" @vimlint(EVL103, 0, a:wl)
" @vimlint(EVL103, 0, a:data)
let s:border_layout.adjust_size = function('s:_border_layout_adjust_size')

function! s:_make_opener(engine, opener, data) abort
  let opener = {
  \ 'engine': a:engine,
  \ 'opener': a:opener,
  \ 'data':   a:data,
  \}

  function! opener.apply(wl, winsize) abort
    if !empty(self.opener)
      execute self.opener
    endif
    if has_key(self.data, 'bufref')
      call a:wl.bufopen(self.data.bufref)
    endif

    " make alias for window
    if has_key(self.data, 'walias')
      call a:wl.walias('.', self.data.walias)
    endif

    " reserve resize
    let size = {}
    if has_key(self.data, 'width')
      let size.width = s:_column_width(a:winsize.width, self.data.width)
    endif
    if has_key(self.data, 'height')
      let size.height = s:_line_height(a:winsize.height, self.data.height)
    endif
    if !empty(size)
      let size.winvar = getwinvar('.', '')
      let self.engine.__size_list += [size]
    endif

    if has_key(self.data, 'layout')
      call self.data.layout.apply()
    endif
  endfunction

  return opener
endfunction

function! s:_column_width(pwinwidth, n) abort
  if type(a:n) == type(0)
    return a:n
  elseif type(a:n) == type(0.0)
    return float2nr(a:pwinwidth * a:n + 0.5)
  else
    return -1
  endif
endfunction

function! s:_line_height(pwinheight, n) abort
  if type(a:n) == type(0)
    return a:n
  elseif type(a:n) == type(0.0)
    return float2nr(a:pwinheight * a:n + 0.5)
  else
    return -1
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: tabstop=2 shiftwidth=2 expandtab
