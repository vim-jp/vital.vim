let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V)
  let s:S = a:V.import('Data.String')
  let s:L = a:V.import('Data.List')
endfunction

function! s:_vital_depends()
  return ['Data.String', 'Data.List']
endfunction

let s:table = {
\ '__column_defs': [],
\ '__hborder': 1,
\ '__vborder': 1,
\ '__header': [],
\ '__rows': [],
\ '__footer': [],
\}

let s:default_column_def = {
\ 'halign': 'left',
\ 'valign': 'top',
\ 'width':  0,
\}

function! s:new(...)
  let obj = deepcopy(s:table)

  if a:0 > 0
    let config = deepcopy(a:1)

    if has_key(config, 'columns')
      call obj.columns(config.columns)
    endif
    if has_key(config, 'hborder')
      call obj.hborder(config.hborder)
    endif
    if has_key(config, 'vborder')
      call obj.vborder(config.vborder)
    endif
    if has_key(config, 'header')
      call obj.header(config.header)
    endif
    if has_key(config, 'rows')
      call obj.rows(config.rows)
    endif
    if has_key(config, 'footer')
      call obj.footer(config.footer)
    endif
  endif

  return obj
endfunction

function! s:table.hborder(...)
  if a:0 == 0
    return self.__hborder
  else
    let self.__hborder = (a:1) ? 1 : 0
  endif
endfunction

function! s:table.vborder(...)
  if a:0 == 0
    return self.__vborder
  else
    let self.__vborder = (a:1) ? 1 : 0
  endif
endfunction

function! s:table.header(...)
  if a:0 == 0
    return deepcopy(self.__header)
  else
    let header = deepcopy(a:1)

    if len(header) != len(self.__column_defs)
      throw "vital: Text.Table: Not match column size."
    endif

    let self.__header = header
  endif
endfunction

function! s:table.columns(...)
  if a:0 == 0
    return deepcopy(self.__column_defs)
  elseif empty(self.__header) && empty(self.__footer) && empty(self.__rows)
    let self.__column_defs = []
    for column_def in a:1
      call self.add_column(column_def)
    endfor
  else
    throw 'vital: Text.Table: Already added header, footer or rows.'
  endif
endfunction

function! s:table.add_column(def)
  let self.__column_defs += [deepcopy(a:def)]
endfunction

function! s:table.rows(...)
  if a:0 == 0
    return deepcopy(self.__rows)
  else
    let self.__rows = []
    for row in a:1
      call self.add_row(row)
    endfor
  endif
endfunction

function! s:table.add_row(row)
  let row = deepcopy(a:row)

  if len(row) != len(self.__column_defs)
    throw "vital: Text.Table: Not match column size."
  endif

  let self.__rows += [row]
endfunction

function! s:table.footer(...)
  if a:0 == 0
    return deepcopy(self.__footer)
  else
    let footer = deepcopy(a:1)

    if len(footer) != len(self.__column_defs)
      throw "vital: Text.Table: Not match column size."
    endif

    let self.__footer = footer
  endif
endfunction

function! s:table.stringify()
  let context = {}

  let context.header = self.__header
  let context.footer = self.__footer
  let context.rows =   self.__rows
  let context.column_defs = []
  for col in range(len(self.__column_defs))
    let orig = self.__column_defs[col]
    let def = extend(deepcopy(s:default_column_def), orig)

    if def.width == 0
      let def.width = max(map(copy([context.header] + context.rows + [context.footer]), 'strdisplaywidth(s:_to_string(v:val[col]))'))
    endif

    let context.column_defs += [def]
  endfor
  let context.hborder = self.__hborder
  let context.vborder = self.__vborder

  return s:_stringify(context)
endfunction

function! s:_stringify(context)
  let buffer = []

  let buffer += s:_make_border_string(a:context)

  if !empty(a:context.header)
    let buffer += s:_make_row_string(a:context, a:context.header)
    let buffer += s:_make_border_string(a:context)
  endif

  for row in a:context.rows
    let buffer += s:_make_row_string(a:context, row)
  endfor

  if !empty(a:context.footer)
    let buffer += s:_make_border_string(a:context)
    let buffer += s:_make_row_string(a:context, a:context.footer)
  endif

  let buffer += s:_make_border_string(a:context)

  return buffer
endfunction

function! s:_make_border_string(context)
  if !a:context.hborder
    return []
  endif

  let buffer = []

  for def in a:context.column_defs
    let width = def.width
    if a:context.vborder
      let width += 2
    endif
    let buffer += [repeat('-', width)]
  endfor

  if a:context.vborder
    return ['+' . join(buffer, '+') . '+']
  else
    return ['-' . join(buffer, '-') . '-']
  endif
endfunction

function! s:_make_row_string(context, row)
  let buffer = []

  for col in range(len(a:context.column_defs))
    let def =  a:context.column_defs[col]
    let cell = a:row[col]

    let buffer += [s:_make_cell_string(def, cell)]

    unlet cell
  endfor

  " vertical align
  let tmp = []
  let col = 0
  for cells in s:_make_equals_size(buffer)
    let def = a:context.column_defs[col]

    let tmp += [s:_valign(def, cells)]

    let col += 1
  endfor
  let buffer = tmp
  unlet tmp

  let out = []
  for cells in s:_zip(buffer)
    let cellstrs = []
    for col in range(len(a:context.column_defs))
      let def = a:context.column_defs[col]
      let cell = cells[col]

      " horizontal align
      let cellstrs += [s:_halign(def, cell)]
    endfor
    if a:context.vborder
      let out += ['| ' . join(cellstrs, ' | ') . ' |']
    elseif a:context.hborder
      let out += [' ' . join(cellstrs, ' ') . ' ']
    else
      let out += [join(cellstrs, ' ')]
    endif
  endfor
  return out
endfunction

function! s:_make_cell_string(def, expr)
  let cellstr = s:_to_string(a:expr)

  " `1' is for a new line
  return s:_wrap(cellstr, a:def.width + 1)
endfunction

function! s:_halign(def, expr)
  if a:def.halign ==# 'left'
    let str = s:_to_string(a:expr)
    while strdisplaywidth(str) < a:def.width
      let str .= ' '
    endwhile
    return str
  elseif a:def.halign ==# 'center'
    let str = s:_to_string(a:expr)
    let n = 0
    while strdisplaywidth(str) < a:def.width
      if n
        let str = ' ' . str
      else
        let str = str . ' '
      endif
      let n = !n
    endwhile
    return str
  elseif a:def.halign ==# 'right'
    let str = s:_to_string(a:expr)
    while strdisplaywidth(str) < a:def.width
      let str = ' ' . str
    endwhile
    return str
  else
    throw printf("vital: Text.Table: Unknown halign `%s'", a:def.halign)
  endif
endfunction

function! s:_valign(def, list)
  if a:def.valign ==# 'top'
    return a:list
  elseif a:def.valign ==# 'center'
    let head_ws = len(s:L.take_while('empty(v:val)', a:list))
    let tail_ws = len(s:L.take_while('empty(v:val)', reverse(copy(a:list))))
    let head_pad = float2nr(floor((head_ws + tail_ws) / 2.0))
    let tail_pad = float2nr(ceil((head_ws + tail_ws) / 2.0))
    return map(range(head_pad), '""') + a:list[head_ws : -(tail_ws + 1)] + map(range(tail_pad), '""')
  elseif a:def.valign ==# 'bottom'
    let buffer = []
    for e in reverse(copy(a:list))
      let buffer += [e]
    endfor
    return buffer
  else
    throw printf("vital: Text.Table: Unknown valign `%s'", a:def.valign)
  endif
endfunction

function! s:_to_string(expr)
  if type(a:expr) == type('')
    return a:expr
  elseif type(a:expr) == type(0)
    return '' . a:expr
  elseif type(a:expr) == type(0.0)
    return printf('%f', a:expr)
  else
    throw 'vital: Text.Table: Unsupported type'
  endif
endfunction

function! s:_make_equals_size(list)
  let mlen = max(map(copy(a:list), 'len(v:val)'))
  let res = []
  for l in a:list
    let res += [map(range(mlen), 'get(l, v:val, "")')]
  endfor
  return res
endfunction

function! s:_zip(list)
  let mlen = max(map(copy(a:list), 'len(v:val)'))
  let zip = []
  for i in range(mlen)
    let buf = []
    for l in a:list
      let buf += [get(l, i, '')]
    endfor
    let zip += [buf]
  endfor
  return zip
endfunction

function! s:_wrap(s, w)
  return s:L.concat(
        \ map(split(a:s, '\r\n\|[\r\n]'), 's:_split_by_displaywidth(v:val, a:w - 1)'))
endfunction

function! s:_split_by_displaywidth(body, x)
  let memo = []
  let body = a:body
  while strdisplaywidth(body) > a:x
    let [tmp, body] = s:_split_by_displaywidth_once(body, a:x)
    call add(memo, tmp)
  endwhile
  call add(memo, body)
  return memo
endfunction

function! s:_split_by_displaywidth_once(body, x)
  let fst = s:_strdisplaywidthpart(a:body, a:x)
  let snd = s:_strdisplaywidthpart_reverse(a:body, strdisplaywidth(a:body) - strdisplaywidth(fst))
  return [fst, snd]
endfunction

function! s:_strdisplaywidthpart(str, width)
  if a:width <= 0
    return ''
  endif
  let rest = split(a:str, '\zs')
  let width = strdisplaywidth(a:str)
  while width > a:width
    let char = s:L.pop(rest)
    let width -= strdisplaywidth(char)
  endwhile
  return join(rest, '')
endfunction

function! s:_strdisplaywidthpart_reverse(str, width)
  if a:width <= 0
    return ''
  endif
  let rest = split(a:str, '\zs')
  let width = strdisplaywidth(a:str)
  while width > a:width
    let char = s:L.shift(rest)
    let width -= strdisplaywidth(char)
  endwhile
  return join(rest, '')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim:set et ts=2 sts=2 sw=2 tw=0:
