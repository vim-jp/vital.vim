let s:save_cpo= &cpo
set cpo&vim

function! s:_vital_loaded(V)
  let s:BM= a:V.import('Vim.BufferManager')
  let s:L=  a:V.import('Data.List')

  for layout_manager in a:V.search('Window.Layout.*')
    let name= matchstr(layout_manager, '\C^Window\.Layout\.\zs\w\+\zeLayout$')
    let s:layout.__layouts[tolower(name)]= a:V.import(layout_manager).new()
  endfor
endfunction

function! s:_vital_depends()
  return [['Window.Layout.*'], 'Vim.BufferManager', 'Data.List']
endfunction

" buffer:
"   id: required
"   bufnr: optional
"   bufname: optional (default: '')
"   range: optional (default: 'tabpage')
"   __manager: internal use
let s:layout= {
\ '__buffers': {},
\ '__layouts': {},
\ '__windows': {},
\}

function! s:new(...)
  let wl= deepcopy(s:layout)

  return wl
endfunction

" layout_data
" ---
" meta data
" ---
" layout:  'layout name'
" walias:  'window name'
"
" layout specific options
" ---
" bufname: 'buffer name'
" north:   {layout_data}
" south:   {layout_data}
" west:    {layout_data}
" east:    {layout_data}
" center:  {layout_data}
" width:   30 or 0.3
" height:  30 or 0.3
"
" limitation
" ---
" north.width = south.width = west.width + center.width + east.width
" north.height + south.height + center.height = parent.height
"
function! s:layout.apply(buffers, layout_data, ...)
  let force= get(a:000, 0, 1)

  if !has_key(a:layout_data, 'layout')
    throw "vital: Window.Layout: You must specify `layout'."
  elseif !has_key(self.__layouts, a:layout_data.layout)
    throw printf("vital: Window.Layout: No such layout manager `%s'.", a:layout_data.layout)
  endif

  " validate
  call self.validate_layout_data(a:layout_data)

  " ensure buffer exists
  for buf in a:buffers
    if !has_key(self.__buffers, buf.id)
      let buf= deepcopy(buf)

      let buf.__manager= s:BM.new({'range': get(buf, 'range', 'tabpage')})
      " use already opened buffer
      if !has_key(buf, 'bufnr')
        let info= buf.__manager.open(get(buf, 'bufname', ''))
        let buf.bufnr= info.bufnr
      else
        call buf.__manager.add(buf.bufnr)
      endif

      if has_key(buf, 'initializer')
        call buf.__manager.move()

        if type(buf.initializer) == type(function('tr'))
          call call(buf.initializer, [])
        elseif type(buf.initializer) == type([])
          call call(buf.initializer[0], [], buf.initializer[1])
        endif
      endif

      let self.__buffers[buf.id]= buf
    endif
  endfor

  " clear tabpage layout
  if force
    only
  endif

  let save_splitright= &splitright
  let save_splitbelow= &splitbelow

  set nosplitright
  set nosplitbelow

  try
    let engine= deepcopy(self.__layouts[a:layout_data.layout])
    call engine.apply(self, deepcopy(a:layout_data))
  finally
    let &splitright= save_splitright
    let &splitbelow= save_splitbelow
  endtry
endfunction

function! s:layout.winnr(walias)
  if !has_key(self.__windows, a:walias)
    return -1
  endif

  for nr in range(1, winnr('$'))
    let winvar= getwinvar(nr, '')

    if winvar is self.__windows[a:walias]
      return nr
    endif
  endfor
  return -1
endfunction

function! s:layout.buffers()
  return values(self.__buffers)
endfunction

function! s:layout.validate_layout_data(data, ...)
  if has_key(a:data, 'layout') && !has_key(self.__layouts, a:data.layout)
    throw printf("vital: Window.Layout: No such layout manager `%s'.", a:data.layout)
  endif

  let workbuf= get(a:000, 0, {'waliases': []})

  " check meta options
  if has_key(a:data, 'walias')
    if s:L.has(workbuf.waliases, a:data.walias)
      throw printf("vital: Window.Layout: Duplicated walias `%s' is not valid.", a:data.walias)
    endif
    let workbuf.waliases+= [a:data.walias]
  endif

  " check engine specific options
  if has_key(a:data, 'layout')
    let engine= self.__layouts[a:data.layout]
    if has_key(engine, 'validate_layout_data')
      call engine.validate_layout_data(self, a:data, workbuf)
    endif
  endif
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
" vim: tabstop=2 shiftwidth=2 expandtab
