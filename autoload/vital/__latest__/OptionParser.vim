let s:save_cpo = &cpo
set cpo&vim

let s:_STRING_TYPE = type('')
let s:_LIST_TYPE = type([])

function! s:_vital_loaded(V)
  let s:L = a:V.import('Data.List')
endfunction

function! s:_vital_depends()
  return ['Data.List']
endfunction

function! s:_make_option_definition_for_help(opt)
  let key = a:opt.definition
  if has_key(a:opt, 'short_option_definition')
    let key .= ', ' . a:opt.short_option_definition
  endif
  return key
endfunction

function! s:_extract_special_opts(argc, argv)
  let ret = {'specials' : {}}
  if a:argc <= 0
    return ret
  endif

  let ret.q_args = a:argv[0]
  for arg in a:argv[1:]
    let arg_type = type(arg)
    if arg_type == s:_LIST_TYPE
      let ret.specials.__range__ = arg
    elseif arg_type == type(0)
      let ret.specials.__count__ = arg
    elseif arg_type == s:_STRING_TYPE
      if arg ==# '!'
        let ret.specials.__bang__ = arg
      elseif arg != ''
        let ret.specials.__reg__ = arg
      endif
    endif
    unlet arg
  endfor
  return ret
endfunction

function! s:_make_args(cmd_args)
  let type = type(a:cmd_args)
  if type == s:_STRING_TYPE
    return split(a:cmd_args)
  elseif type == s:_LIST_TYPE
    return map(copy(a:cmd_args), 'type(v:val) == s:_STRING_TYPE ? v:val : string(v:val)')
  else
    throw 'vital: OptionParser: Invalid type: first argument of parse() should be string or list of string'
  endif
endfunction

function! s:_expand_short_option(arg, options)
  let short_opt = matchstr(a:arg, '^-[^- =]\>')
  for [name, value] in items(a:options)
    if get(value, 'short_option_definition', '') ==# short_opt
      return substitute(a:arg, short_opt, '--' . name, '')
    endif
  endfor
  return a:arg
endfunction

function! s:_parse_arg(arg, options)
  " if --no-hoge pattern
  if a:arg =~# '^--no-[^= ]\+'
    " get hoge from --no-hoge
    let key = matchstr(a:arg, '^--no-\zs[^= ]\+')
    if has_key(a:options, key) && has_key(a:options[key], 'no')
      return [key, 0]
    endif

    " if --hoge pattern
  elseif a:arg =~# '^--[^= ]\+$'
    " get hoge from --hoge
    let key = matchstr(a:arg, '^--\zs[^= ]\+')
    if has_key(a:options, key)
      if has_key(a:options[key], 'has_value')
        throw 'vital: OptionParser: Must specify value for option: ' . key
      endif
      return [key, 1]
    endif

    " if --hoge=poyo pattern
  else
    " get hoge from --hoge=poyo
    let key = matchstr(a:arg, '^--\zs[^= ]\+')
    if has_key(a:options, key)
      " get poyo from --hoge=poyo
      return [key, matchstr(a:arg, '^--[^= ]\+=\zs\S\+$')]
    endif
  endif

  return a:arg
endfunction

function! s:_parse_args(cmd_args, options)
  let parsed_args = {}
  let unknown_args = []
  let args = s:_make_args(a:cmd_args)

  for arg in args

    " replace short option with long option if short option is available
    if arg =~# '^-[^- =]\>'
      let arg = s:_expand_short_option(arg, a:options)
    endif

    " check if arg is --[no-]hoge[=VALUE]
    if arg !~# '^--\%(no-\)\=[^= ]\+\%(=\S\+\)\=$'
      call add(unknown_args, arg)
      continue
    endif

    let parsed_arg = s:_parse_arg(arg, a:options)
    if type(parsed_arg) == s:_LIST_TYPE
      let parsed_args[parsed_arg[0]] = parsed_arg[1]
    else
      call add(unknown_args, parsed_arg)
    endif
  endfor

  return [parsed_args, unknown_args]
endfunction

let s:_DEFAULT_PARSER = {'options' : {}}

function! s:_DEFAULT_PARSER.help()
  let definitions = map(values(self.options), "[s:_make_option_definition_for_help(v:val), v:val.description]")
  let key_width = len(s:L.max_by(definitions, 'len(v:val[0])')[0])
  return "Options:\n" .
        \ join(map(definitions, '
        \ "  " . v:val[0] .
        \ repeat(" ", key_width - len(v:val[0])) . " : " .
        \ v:val[1]
        \ '), "\n")
endfunction

function! s:_DEFAULT_PARSER.parse(...)
  let opts = s:_extract_special_opts(a:0, a:000)
  if ! has_key(opts, 'q_args')
    return opts.specials
  endif

  if ! get(self, 'disable_auto_help', 0)
        \  && opts.q_args ==# '--help'
        \  && ! has_key(self.options, 'help')
    echo self.help()
    return extend(opts.specials, {'help' : 1, '__unknown_args__' : []})
  endif

  let parsed_args = s:_parse_args(opts.q_args, self.options)

  let ret = parsed_args[0]
  call extend(ret, opts.specials)
  let ret.__unknown_args__ = parsed_args[1]
  return ret
endfunction

function! s:_DEFAULT_PARSER.on(...)
  if ! (a:0 == 2 || a:0 == 3)
    throw 'vital: OptionParser: Wrong number of arguments: ' . a:0 . ' for 2 or 3'
  endif

  " get hoge and huga from --hoge=huga
  let [name, value] = matchlist(a:1, '^--\([^= ]\+\)\(=\S\+\)\=$')[1:2]
  if value != ''
    let has_value = 1
  endif

  if name =~# '^\[no-]'
    let no = 1
    let name = matchstr(name, '^\[no-]\zs.\+')
  endif

  if name == ''
    throw 'vital: OptionParser: Option of key is invalid: ' . a:1
  endif

  let self.options[name] = {'definition' : a:1, 'description' : a:000[-1]}
  if exists('l:no')
    let self.options[name].no = 1
  endif
  if exists('l:has_value')
    let self.options[name].has_value = 1
  endif

  " if short option is specified
  if a:0 == 3
    if a:2 !~# '^-[^- =]$'
      throw 'vital: OptionParser: Short option is invalid: ' . a:2
    endif

    let self.options[name].short_option_definition = a:2
  endif

  return self
endfunction

lockvar! s:_DEFAULT_PARSER

function! s:new()
  return deepcopy(s:_DEFAULT_PARSER)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
