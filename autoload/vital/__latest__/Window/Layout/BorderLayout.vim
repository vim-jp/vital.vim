let s:save_cpo= &cpo
set cpo&vim

function! s:_vital_loaded(V)
endfunction

function! s:_vital_depends()
  return []
endfunction

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
let s:border_layout= {
\ '__size_list': [],
\}

function! s:new()
  return deepcopy(s:border_layout)
endfunction

function! s:border_layout.validate_layout_data(wl, data, workbuf)
  for region in ['north', 'south', 'west', 'center', 'east']
    if has_key(a:data, region)
      call a:wl.validate_layout_data(a:data[region], a:workbuf)
    endif
  endfor
endfunction

function! s:border_layout.do_layout(wl, data)
  " adjust
  if !has_key(a:data, 'center')
    if has_key(a:data, 'west')
      let a:data.center= a:data.west
      unlet a:data.west
    elseif has_key(a:data, 'east')
      let a:data.center= a:data.east
      unlet a:data.east
    elseif has_key(a:data, 'north')
      let a:data.center= a:data.north
      unlet a:data.north
    elseif has_key(a:data, 'south')
      let a:data.center= a:data.south
      unlet a:data.south
    endif
  endif

  " split vertical
  let openers= []
  if has_key(a:data, 'north')
    let openers+= [self.make_opener('aboveleft split', a:data.north)]
  endif
  if has_key(a:data, 'south')
    let openers+= [self.make_opener('belowright split', a:data.south)]
  endif

  " split horizontal
  if has_key(a:data, 'east')
    let openers+= [self.make_opener('belowright vsplit', a:data.east)]
  endif
  if has_key(a:data, 'west')
    let openers+= [self.make_opener('aboveleft vsplit', a:data.west)]
  endif
  if has_key(a:data, 'center')
    let openers+= [self.make_opener('', a:data.center)]
  endif

  let winsize= {'width': winwidth('.'), 'height': winheight('.')}
  " do layout
  for opener in openers
    let winvar= getwinvar('.', '')
    call opener.apply(a:wl, winsize)
    for nr in range(1, winnr('$'))
      if getwinvar(nr, '') is winvar
        execute nr 'wincmd w'
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

function! s:border_layout.adjust_size(wl, data)
  " adjust size
  let winvar= getwinvar('.', '')
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

function! s:border_layout.make_opener(opener, data)
  let opener= {
  \ 'engine': self,
  \ 'opener': a:opener,
  \ 'data':   a:data,
  \}

  function! opener.apply(wl, winsize)
    if !empty(self.opener)
      execute self.opener
    endif
    if has_key(self.data, 'bufref')
      let bufid= self.data.bufref
      let bufnr= a:wl.__buffers[bufid].bufnr

      execute 'buffer' bufnr
    endif

    " make alias for window
    if has_key(self.data, 'walias')
      let a:wl.__windows[self.data.walias]= getwinvar('.', '')
    endif

    " reserve resize
    let size= {}
    if has_key(self.data, 'width')
      let size.width= s:_column_width(a:winsize.width, self.data.width)
    endif
    if has_key(self.data, 'height')
      let size.height= s:_line_height(a:winsize.height, self.data.height)
    endif
    if !empty(size)
      let size.winvar= getwinvar('.', '')
      let self.engine.__size_list+= [size]
    endif

    if has_key(self.data, 'north') || has_key(self.data, 'south') ||
    \  has_key(self.data, 'east') || has_key(self.data, 'west') ||
    \  has_key(self.data, 'center')
      call a:wl.do_layout(self.data)
    endif
  endfunction

  return opener
endfunction

function! s:_column_width(pwinwidth, n)
  if type(a:n) == type(0)
    return a:n
  elseif type(a:n) == type(0.0)
    return float2nr(a:pwinwidth * a:n + 0.5)
  else
    return -1
  endif
endfunction

function! s:_line_height(pwinheight, n)
  if type(a:n) == type(0)
    return a:n
  elseif type(a:n) == type(0.0)
    return float2nr(a:pwinheight * a:n + 0.5)
  else
    return -1
  endif
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
" vim: tabstop=2 shiftwidth=2 expandtab
