let s:self_version = expand('<sfile>:t:r')
function! s:import(name)"{{{
  let namespace = substitute(a:name, '\W\+', '#', 'g')
  try
    let module = vital#{s:self_version}#{namespace}#new()
  catch /^Vim\%((\a\+)\)\?:E117/
    throw 'vital: module not found: ' . a:name
  endtry
  return module
endfunction"}}}

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
function! s:func(name)"{{{
  return function(matchstr(expand('<sfile>'), '<SNR>\d\+_\zefunc$') . a:name)
endfunction"}}}

function! vital#{s:self_version}#new()
  " FIXME: Should automate.
  return {
  \   'import': s:func('import'),
  \   'truncate_smart': s:func('truncate_smart'),
  \   'truncate': s:func('truncate'),
  \   'strchars': s:func('strchars'),
  \   'strwidthpart': s:func('strwidthpart'),
  \   'strwidthpart_reverse': s:func('strwidthpart_reverse'),
  \   'wcswidth': s:func('wcswidth'),
  \   'wcwidth': s:func('wcwidth'),
  \   'is_win': s:func('is_win'),
  \   'print_error': s:func('print_error'),
  \   'smart_execute_command': s:func('smart_execute_command'),
  \   'escape_file_searching': s:func('escape_file_searching'),
  \   'escape_pattern': s:func('escape_pattern'),
  \   'set_default': s:func('set_default'),
  \   'set_dictionary_helper': s:func('set_dictionary_helper'),
  \   'substitute_path_separator': s:func('substitute_path_separator'),
  \   'path2directory': s:func('path2directory'),
  \   'path2project_directory': s:func('path2project_directory'),
  \   'has_vimproc': s:func('has_vimproc'),
  \   'system': s:func('system'),
  \   'get_last_status': s:func('get_last_status'),
  \ }
endfunction
" vim: foldmethod=marker
