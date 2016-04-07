" String interpolation in Vim script
let s:save_cpo = &cpo
set cpo&vim

function! s:interpolate(string, ...) abort
  let context = get(a:, 1, {})
  let str = a:string
  let ps = s:_parse_first_idx_range(str)
  while !empty(ps)
    let [s, e] = ps
    let expr = str[(s + len(s:_parser_config._ps)):(e - len(s:_parser_config._pend))]
    let V = s:_context_eval(expr, context)
    let str = (s > 0 ? str[0:(s-1)] : '') . V . str[(e+1):]
    let ps = s:_parse_first_idx_range(str, s + len(V))
    unlet V
  endwhile
  return str
endfunction

"" Contextual eval()
" NOTE: Old vim doesn't support extending l:
" call extend(l:, a:context)
function! s:_context_eval(expr, context) abort
  for s:key in filter(keys(a:context), "v:val =~# '^\\h\\w*$'")
    if type(a:context[s:key]) is# type(function('tr')) && s:key !~# '^\u'
      continue
    endif
    let {s:key} = a:context[s:key]
  endfor
  sandbox return eval(a:expr)
endfunction

" Pair Parser:
let s:_parser_config = {}
let s:_parser_config._ppr = '$' " pattern prefix
let s:_parser_config._psb = '{' " pattern start bracket
let s:_parser_config._ps = s:_parser_config._ppr . s:_parser_config._psb " pattern start
let s:_parser_config._peb = '}' " pattern end bracket
let s:_parser_config._psu = '' " pattern suffix
let s:_parser_config._pend = s:_parser_config._peb . s:_parser_config._psu " pattern end

" return [start_index, end_index] or [] if not found
function! s:_parse_first_idx_range(str, ...) abort
  let i = get(a:, 1, 0)
  let level = 0
  let str_state = ''
  let str_DOUBLE = '"'
  let str_SINGLE = "'"
  while i < len(a:str)
    if a:str[(i):(i + len(s:_parser_config._ps)-1)] is# s:_parser_config._ps
      let j = i + len(s:_parser_config._ps)
      while j < len(a:str)
        if a:str[j] is# str_DOUBLE && str_state is# str_DOUBLE
          let str_state = ''
        elseif a:str[j] is# str_DOUBLE && str_state isnot# str_SINGLE
          let str_state = str_DOUBLE
        elseif a:str[j] is# str_SINGLE && str_state is# str_SINGLE
          let str_state = ''
        elseif a:str[j] is# str_SINGLE && str_state isnot# str_DOUBLE
          let str_state = str_SINGLE
        elseif str_state isnot# ''
          " pass
        elseif a:str[(j):(j + len(s:_parser_config._psb)-1)] is# s:_parser_config._psb
          let level += 1
        elseif a:str[(j):(j + len(s:_parser_config._pend)-1)] is# s:_parser_config._pend
          let level -= 1
          if level < 0
            return [i, j]
          endif
        elseif a:str[(j):(j + len(s:_parser_config._psb)-1)] is# s:_parser_config._psb
          let level -= 1
        endif
        let j += 1
      endwhile
    endif
    let i += 1
  endwhile
  return [] " not found
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
