let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:BM = a:V.import('Vim.BufferManager')
  let s:L =  a:V.import('Data.List')

  for layout_manager in a:V.search('Vim.WindowLayout.*')
    " gather some kind of layout engines, located under Vim.WindowLayout namespace
    let name = matchstr(layout_manager, '\C^Vim\.WindowLayout\.\zs\w\+\zeLayout$')
    let s:layout.__layouts[tolower(name)] = a:V.import(layout_manager).new()
  endfor
endfunction

function! s:_vital_depends() abort
  return ['Vim.WindowLayout.*', 'Vim.BufferManager', 'Data.List']
endfunction

" buffer:
"   id: required
"   bufnr: optional
"   bufname: optional (default: '')
"   range: optional (default: 'tabpage')
"   __manager: internal use
let s:layout = {
\ '__buffers': {},
\ '__layouts': {},
\ '__windows': {},
\}

function! s:new(...) abort
  let wl = deepcopy(s:layout)

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
" function! s:layout.apply(buffers, layout_data, ...) abort
function! s:_layout_apply(buffers, layout_data, ...) dict abort
  " XXX: force is an internal option
  let force = get(a:000, 0, 1)

  if !has_key(a:layout_data, 'layout')
    throw "vital: Vim.WindowLayout: You must specify `layout'."
  elseif !has_key(self.__layouts, a:layout_data.layout)
    throw printf("vital: Vim.WindowLayout: No such layout manager `%s'.", a:layout_data.layout)
  endif

  " " validate
  " call self.validate_layout_data(a:layout_data)

  " ensure buffer exists
  for buf in a:buffers
    if !has_key(self.__buffers, buf.id)
      let buf = deepcopy(buf)

      let buf.__manager = s:BM.new({'range': get(buf, 'range', 'tabpage')})
      " use already opened buffer
      if !has_key(buf, 'bufnr')
        let info = buf.__manager.open(get(buf, 'bufname', ''))
        let buf.bufnr = info.bufnr
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

      let self.__buffers[buf.id] = buf
    endif
  endfor

  " clear tabpage layout
  if force
    only
  endif

  let save_splitright = &splitright
  let save_splitbelow = &splitbelow

  set nosplitright
  set nosplitbelow

  try
    " support recursively layout
    let layout_data = self.prepare(deepcopy(a:layout_data))

    call layout_data.layout.apply()
    call layout_data.layout.adjust_size()
  finally
    let &splitright = save_splitright
    let &splitbelow = save_splitbelow
  endtry
endfunction
let s:layout.apply = function('s:_layout_apply')

function! s:_layout_prepare(layout_data) dict abort
  if !has_key(a:layout_data, 'layout')
    return a:layout_data
  endif

  let a:layout_data.layout = s:_new_facade(self, self.__layouts[a:layout_data.layout], a:layout_data)

  " walias is important for later reference
  if !has_key(a:layout_data, 'walias')
    " TODO: UUID is better than time based string
    let a:layout_data.walias = reltimestr(reltime())
  endif

  for [key, value] in items(a:layout_data)
    if key ==# 'layout'
      unlet value
      continue
    endif

    if type(value) == type([])
      for elm in value
        call self.prepare(elm)
      endfor
    elseif type(value) == type({})
      call self.prepare(value)
    endif
    unlet value
  endfor

  return a:layout_data
endfunction
let s:layout.prepare = function('s:_layout_prepare')

function! s:_layout_walias(winnr, alias) dict abort
  let self.__windows[a:alias] = getwinvar(a:winnr, '')
endfunction
let s:layout.walias = function('s:_layout_walias')

function! s:_layout_winnr(walias) dict abort
  if !has_key(self.__windows, a:walias)
    return -1
  endif

  for nr in range(1, winnr('$'))
    let winvar = getwinvar(nr, '')

    if winvar is self.__windows[a:walias]
      return nr
    endif
  endfor
  return -1
endfunction
let s:layout.winnr = function('s:_layout_winnr')

function! s:_layout_bufopen(id) dict abort
  let buf = self.__buffers[a:id]
  execute 'buffer' buf.bufnr
endfunction
let s:layout.bufopen = function('s:_layout_bufopen')

function! s:_layout_buffer(id) dict abort
  return self.__buffers[a:id]
endfunction
let s:layout.buffer = function('s:_layout_buffer')

function! s:_layout_buffers() dict abort
  return values(self.__buffers)
endfunction
let s:layout.buffers = function('s:_layout_buffers')

" function! s:layout.validate_layout_data(data, ...) abort
"   if has_key(a:data, 'layout') && !has_key(self.__layouts, a:data.layout)
"     throw printf("vital: Vim.WindowLayout: No such layout manager `%s'.", a:data.layout)
"   endif
" 
"   let workbuf = get(a:000, 0, {'waliases': []})
" 
"   " check meta options
"   if has_key(a:data, 'walias')
"     if s:L.has(workbuf.waliases, a:data.walias)
"       throw printf("vital: Vim.WindowLayout: Duplicated walias `%s' is not valid.", a:data.walias)
"     endif
"     let workbuf.waliases += [a:data.walias]
"   endif
" 
"   " check engine specific options
"   if has_key(a:data, 'layout')
"     let engine = self.__layouts[a:data.layout]
"     if has_key(engine, 'validate_layout_data')
"       call engine.validate_layout_data(self, a:data, workbuf)
"     endif
"   endif
" endfunction

let s:facade = {}

function! s:_new_facade(wl, engine, layout_data) abort
  let facade = deepcopy(s:facade)
  let facade.__wl = a:wl
  let facade.__engine = a:engine
  let facade.__layout_data = a:layout_data
  return facade
endfunction

function! s:_facade_apply() dict abort
  call self.__engine.apply(self.__wl, self.__layout_data)
endfunction
let s:facade.apply = function('s:_facade_apply')

function! s:_facade_adjust_size() dict abort
  call self.__engine.adjust_size(self.__wl, self.__layout_data)
endfunction
let s:facade.adjust_size = function('s:_facade_adjust_size')

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: tabstop=2 shiftwidth=2 expandtab
