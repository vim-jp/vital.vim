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

let s:default_table_style = {
\ 'max_width': 0,
\}
let s:default_column_style = {
\ 'halign': 'left',
\ 'valign': 'top',
\ 'width':  0,
\ 'min_width': 0,
\ 'max_width': 0,
\}
let s:default_cell_style = {
\ 'halign': 'left',
\ 'valign': 'top',
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
  else
    let save_column_defs = self.__column_defs
    try
      let self.__column_defs = []
      for column_def in a:1
        call self.add_column(column_def)
      endfor
    catch /^vital: Text\.Table:/
      let self.__column_defs = save_column_defs
      throw v:exception
    endtry
  endif
endfunction

function! s:table.add_column(def)
  if !(empty(self.__header) && empty(self.__footer) && empty(self.__rows))
    throw 'vital: Text.Table: Already added header, footer or rows.'
  endif

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

function! s:table.stringify(...)
  let context = {}

  let context.hborder = self.__hborder
  let context.vborder = self.__vborder
  let context.hpadding = 1
  let context.table_style = extend(deepcopy(s:default_table_style), get(a:000, 0, {}))
  let context.ncolumns = len(self.__column_defs)
  let context.column_styles = map(copy(self.__column_defs), 'extend(deepcopy(s:default_column_style), v:val)')

  " trans header
  let context.has_header = !empty(self.__header)
  if context.has_header
    let context.header = s:_make_internal_row_object(context.column_styles, self.__header)
  endif
  " trans rows
  let context.rows = []
  for row in self.__rows
    let context.rows += [s:_make_internal_row_object(context.column_styles, row)]
  endfor
  " trans footer
  let context.has_footer = !empty(self.__footer)
  if context.has_footer
    let context.footer = s:_make_internal_row_object(context.column_styles, self.__footer)
  endif

  " compute each column width
  let context.widths = s:_compute_widths(context)

  return s:_stringify(context)
endfunction

function! s:_compute_width_ranges(context)
  let rows = []
  if a:context.has_header
    let rows += [a:context.header]
  endif
  let rows += a:context.rows
  if a:context.has_footer
    let rows += [a:context.footer]
  endif

  let ranges = []
  for colidx in range(a:context.ncolumns)
    " texts = [[''], ...]
    let texts = map(copy(rows), 'v:val[colidx].text')
    " TODO: see word length
    let min = 2
    let max = max(map(copy(texts), "max(map(copy(v:val), 'strdisplaywidth(v:val)'))"))

    let ranges += [[min, max]]
  endfor
  return ranges
endfunction

function! s:_compute_widths(context)
  let ranges = s:_compute_width_ranges(a:context)

  let widths = []
  for container in s:L.zip(ranges, a:context.column_styles)
    let range = container[0]
    let style = container[1]

    let max_width = (style.max_width > 0) ? style.max_width : range[1]
    let min_width = (style.min_width > 0) ? style.min_width : range[0]
    " default is max one
    let width = max_width
    let fixed = 0

    " fix width if exists width which was specified by user
    if style.width > 0
      let width = style.width
      let fixed = 1
    endif

    " use minimum width if width less than minimum width
    if width < min_width
      let width = min_width
    endif

    let widths += [{'width': width, 'fixed': fixed, 'min_width': min_width, 'max_width': max_width}]
  endfor

  let table_width = s:_compute_table_width(a:context)

  if a:context.table_style.max_width <= 0 || table_width >= s:L.foldl('v:memo + v:val.width', 0, widths)
    return map(copy(widths), 'v:val.width')
  else
    while table_width < s:L.foldl('v:memo + v:val.width', 0, widths)
      let fixed_widths = filter(copy(widths), 'v:val.fixed')
      let nonfixed_widths = filter(copy(widths), '!v:val.fixed')
      let free_width = abs(a:context.table_style.max_width - s:L.foldl('v:memo + v:val.width', 0, fixed_widths))

      if empty(nonfixed_widths)
        break
      endif

      " distribute free width to each non-fixed width
      for w in nonfixed_widths
        " ratio by logarithm for natural distribution
        let w.width -= float2nr(free_width * (log(w.max_width) / s:L.foldl('v:memo + v:val.max_width', 0.0, nonfixed_widths)) + 0.5)

        if w.width < w.min_width
          let w.width = w.min_width
          let w.fixed = 1
        endif
      endfor
    endwhile

    return map(copy(widths), 'v:val.width')
  endif
endfunction

function! s:_compute_table_width(context)
  if a:context.table_style.max_width <= 0
    " not specified
    return 0
  endif

  let width = a:context.table_style.max_width

  " | xxx | xxx |
  if a:context.vborder
    let width -= strdisplaywidth('|') * (a:context.ncolumns + 1)
  endif

  let width -= a:context.hpadding * 2 * a:context.ncolumns

  return width
endfunction

function! s:_make_internal_row_object(defs, row)
  let irow = []
  for container in s:L.zip(a:row, a:defs)
    if type(container[0]) == type({})
      let text =  get(container[0], 'text', '')
      let style = get(container[0], 'style', container[1])
    else
      let text =  container[0]
      let style = container[1]
    endif

    let irow += [{
    \ 'style': extend(deepcopy(s:default_column_style), style),
    \ 'text':  split(s:_to_string(text), "\n"),
    \}]
  endfor
  return irow
endfunction

function! s:_stringify(context)
  let buffer = []

  let buffer += s:_make_border_string(a:context)

  if a:context.has_header
    let buffer += s:_make_row_string(a:context, a:context.header)
    let buffer += s:_make_border_string(a:context)
  endif

  for row in a:context.rows
    let buffer += s:_make_row_string(a:context, row)
  endfor

  if a:context.has_footer
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

  for width in a:context.widths
    if a:context.vborder
      let width += a:context.hpadding * 2
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
  let row = deepcopy(a:row)

  for colidx in range(a:context.ncolumns)
    let cell = row[colidx]

    let cell.text = s:_wrap(cell.text, a:context.widths[colidx])
  endfor

  " vertical align
  let row = s:_make_equals_size(row)
  for cell in row
    let cell.text = s:_valign(cell.style, cell.text)
  endfor

  let out = []
  let padding = repeat(' ', a:context.hpadding)
  for htexts in call(s:L.zip, map(copy(row), '!empty(v:val.text) ? v:val.text : [""]'))
    let cellstrs = []
    for colidx in range(a:context.ncolumns)
      " horizontal align
      let cellstrs += [s:_halign(row[colidx].style, htexts[colidx], a:context.widths[colidx])]
    endfor
    if a:context.vborder
      let out += ['|' . padding . join(cellstrs, padding . '|' . padding) . padding . '|']
    elseif a:context.hborder
      let out += [padding . join(cellstrs, padding) . padding]
    else
      let out += [join(cellstrs, padding)]
    endif
  endfor
  return out
endfunction

function! s:_halign(style, str, width)
  if a:style.halign ==# 'left'
    let str = a:str
    while strdisplaywidth(str) < a:width
      let str .= ' '
    endwhile
    return str
  elseif a:style.halign ==# 'center'
    let str = a:str
    let n = 0
    while strdisplaywidth(str) < a:width
      if n
        let str = ' ' . str
      else
        let str = str . ' '
      endif
      let n = !n
    endwhile
    return str
  elseif a:style.halign ==# 'right'
    let str = a:str
    while strdisplaywidth(str) < a:width
      let str = ' ' . str
    endwhile
    return str
  else
    throw printf("vital: Text.Table: Unknown halign `%s'", a:style.halign)
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

function! s:_make_equals_size(row)
  let row = deepcopy(a:row)
  let mlen = max(map(copy(row), 'len(v:val.text)'))
  for cell in row
    let cell.text = map(range(mlen), 'get(cell.text, v:val, "")')
  endfor
  return row
endfunction

function! s:_wrap(text, width)
  return s:L.concat(
  \ map(a:text, 's:_split_by_displaywidth(v:val, a:width)'))
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
