let s:base_dir = expand('<sfile>:r')
let s:self_version = expand('<sfile>:t:r')
function! s:import(name)"{{{
  return s:_import(a:name, s:_scripts())
endfunction"}}}

function! s:load(...) dict
  let scripts = s:_scripts()
  for name in a:000
    let target = split(name, '\W\+')
    let dict = self
    while 2 <= len(target)
      let ns = remove(target, 0)
      if !has_key(dict, ns)
        let dict[ns] = {}
      endif
      if type(dict[ns]) == type({})
        let dict = dict[ns]
      else
        let target = []
      endif
    endwhile

    if !empty(target) && !has_key(dict, target[0])
      let dict[target[0]] = s:_import(name, scripts)
    endif
  endfor
  return self
endfunction

function! s:_import(name, scripts)
  if type(a:name) == type(0)
    return s:_build_module(a:name)
  endif
  let target = a:name == '' ? '' : '/' . substitute(a:name, '\W\+', '/', 'g')
  let pat = substitute(s:base_dir . target, '[/\\]', '[/\\\\]', 'g') . '\.vim$'
  let sid = 0
  for script in a:scripts
    if script =~? pat
      let sid = matchstr(script, '^\s*\zs\d\+') - 0
      break
    endif
  endfor
  if !sid
    try
      source `=s:base_dir . target . '.vim'`
    catch /^Vim\%((\a\+)\)\?:E484/
      throw 'vital: module not found: ' . a:name
    endtry
    let sid = len(a:scripts) + 1  " We expect that the file newly read is +1.
  endif
  return s:_build_module(sid)
endfunction

function! s:_scripts()
  redir => scripts
    silent! scriptnames
  redir END
  return split(scripts, "\n")
endfunction

function! s:_build_module(sid)
  let prefix = '<SNR>' . a:sid . '_'
  redir => funcs
    silent! function
  redir END
  let filter_pat = '^function ' . prefix . '\a'
  let map_pat = prefix . '\zs\w\+'
  let functions = map(filter(split(funcs, "\n"), 'v:val =~# filter_pat'),
  \          'matchstr(v:val, map_pat)')

  let module = {}
  for func in functions
    let module[func] = function(prefix . func)
  endfor
  return module
endfunction

function! vital#{s:self_version}#new()
  return s:import('')
endfunction


" TODO Move the following functions to the appropriate module.

function! s:truncate_smart(str, max, footer_width, separator)"{{{
  let width = s:wcswidth(a:str)
  if width <= a:max
    let ret = a:str
  else
    let header_width = a:max - s:wcswidth(a:separator) - a:footer_width
    let ret = s:strwidthpart(a:str, header_width) . a:separator
          \ . s:strwidthpart_reverse(a:str, a:footer_width)
  endif

  return s:truncate(ret, a:max)
endfunction"}}}

function! s:truncate(str, width)"{{{
  " Original function is from mattn.
  " http://github.com/mattn/googlereader-vim/tree/master

  let ret = a:str
  let width = s:wcswidth(a:str)
  if width > a:width
    let ret = s:strwidthpart(ret, a:width)
    let width = s:wcswidth(ret)
  endif

  if width < a:width
    let ret .= repeat(' ', a:width - width)
  endif

  return ret
endfunction"}}}

function! s:strchars(str)"{{{
  return len(substitute(a:str, '.', 'x', 'g'))
endfunction"}}}

function! s:strwidthpart(str, width)"{{{
  let ret = a:str
  let width = s:wcswidth(a:str)
  while width > a:width
    let char = matchstr(ret, '.$')
    let ret = ret[: -1 - len(char)]
    let width -= s:wcwidth(char)
  endwhile

  return ret
endfunction"}}}
function! s:strwidthpart_reverse(str, width)"{{{
  let ret = a:str
  let width = s:wcswidth(a:str)
  while width > a:width
    let char = matchstr(ret, '^.')
    let ret = ret[len(char) :]
    let width -= s:wcwidth(char)
  endwhile

  return ret
endfunction"}}}

if v:version >= 703
  " Use builtin function.
  function! s:wcswidth(str)"{{{
    return strdisplaywidth(a:str)
  endfunction"}}}
  function! s:wcwidth(str)"{{{
    return strwidth(a:str)
  endfunction"}}}
else
  function! s:wcswidth(str)"{{{
    if a:str =~# '^[\x00-\x7f]*$'
      return strlen(a:str)
    end

    let mx_first = '^\(.\)'
    let str = a:str
    let width = 0
    while 1
      let ucs = char2nr(substitute(str, mx_first, '\1', ''))
      if ucs == 0
        break
      endif
      let width += s:wcwidth(ucs)
      let str = substitute(str, mx_first, '', '')
    endwhile
    return width
  endfunction"}}}

  " UTF-8 only.
  function! s:wcwidth(ucs)"{{{
    let ucs = a:ucs
    if (ucs >= 0x1100
          \  && (ucs <= 0x115f
          \  || ucs == 0x2329
          \  || ucs == 0x232a
          \  || (ucs >= 0x2e80 && ucs <= 0xa4cf
          \      && ucs != 0x303f)
          \  || (ucs >= 0xac00 && ucs <= 0xd7a3)
          \  || (ucs >= 0xf900 && ucs <= 0xfaff)
          \  || (ucs >= 0xfe30 && ucs <= 0xfe6f)
          \  || (ucs >= 0xff00 && ucs <= 0xff60)
          \  || (ucs >= 0xffe0 && ucs <= 0xffe6)
          \  || (ucs >= 0x20000 && ucs <= 0x2fffd)
          \  || (ucs >= 0x30000 && ucs <= 0x3fffd)
          \  ))
      return 2
    endif
    return 1
  endfunction"}}}
endif

function! s:is_win()"{{{
  return has('win16') || has('win32') || has('win64')
endfunction"}}}

function! s:print_error(message)"{{{
  echohl WarningMsg | echomsg a:message | echohl None
endfunction"}}}

function! s:smart_execute_command(action, word)"{{{
  execute a:action . ' ' . (a:word == '' ? '' : '`=a:word`')
endfunction"}}}

function! s:escape_file_searching(buffer_name)"{{{
  return escape(a:buffer_name, '*[]?{},')
endfunction"}}}
function! s:escape_pattern(str)"{{{
  return escape(a:str, '~"\.^$[]*')
endfunction"}}}

function! s:set_default(var, val)  "{{{
  if !exists(a:var) || type({a:var}) != type(a:val)
    let {a:var} = a:val
  endif
endfunction"}}}
function! s:set_dictionary_helper(variable, keys, pattern)"{{{
  for key in split(a:keys, ',')
    if !has_key(a:variable, key)
      let a:variable[key] = a:pattern
    endif
  endfor
endfunction"}}}
function! s:substitute_path_separator(path)"{{{
  return s:is_win() ? substitute(a:path, '\\', '/', 'g') : a:path
endfunction"}}}
function! s:path2directory(path)"{{{
  return s:substitute_path_separator(isdirectory(a:path) ? a:path : fnamemodify(a:path, ':p:h'))
endfunction"}}}
function! s:path2project_directory(path)"{{{
  let l:search_directory = s:path2directory(a:path)
  let l:directory = ''

  " Search VCS directory.
  for d in ['.git', '.bzr', '.hg']
    let d = finddir(d, s:escape_file_searching(l:search_directory) . ';')
    if d != ''
      let l:directory = fnamemodify(d, ':p:h:h')
      break
    endif
  endfor

  " Search project file.
  if l:directory == ''
    for d in ['build.xml', 'prj.el', '.project', 'pom.xml', 'Makefile', 'configure', 'Rakefile', 'NAnt.build', 'tags', 'gtags']
      let d = findfile(d, s:escape_file_searching(l:search_directory) . ';')
      if d != ''
        let l:directory = fnamemodify(d, ':p:h')
        break
      endif
    endfor
  endif

  if l:directory == ''
    " Search /src/ directory.
    let l:base = s:substitute_path_separator(l:search_directory)
    if l:base =~# '/src/'
      let l:directory = l:base[: strridx(l:base, '/src/') + 3]
    endif
  endif

  if l:directory == ''
    let l:directory = l:search_directory
  endif

  return s:substitute_path_separator(l:directory)
endfunction"}}}
" Check vimproc."{{{
let s:exists_vimproc = globpath(&rtp, 'autoload/vimproc.vim') != ''
"}}}
function! s:has_vimproc()"{{{
  return s:exists_vimproc
endfunction"}}}
function! s:system(str, ...)"{{{
  let l:command = a:str
  let l:input = a:0 >= 1 ? a:1 : ''
  if &termencoding != '' && &termencoding != &encoding
    let l:command = iconv(l:command, &encoding, &termencoding)
    let l:input = iconv(l:input, &encoding, &termencoding)
  endif

  if a:0 == 0
    let l:output = s:has_vimproc() ?
          \ vimproc#system(l:command) : system(l:command)
  else
    let l:output = s:has_vimproc() ?
          \ vimproc#system(l:command, l:input) : system(l:command, l:input)
  endif

  if &termencoding != '' && &termencoding != &encoding
    let l:output = iconv(l:output, &termencoding, &encoding)
  endif

  return l:output
endfunction"}}}
function! s:get_last_status()"{{{
  return s:has_vimproc() ?
        \ vimproc#get_last_status() : v:shell_error
endfunction"}}}
" vim: foldmethod=marker
