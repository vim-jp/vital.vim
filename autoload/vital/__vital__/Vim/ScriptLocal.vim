scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

""" Helper:

function! s:_throw(message) abort
  throw printf('vital: Vim.ScriptLocal: %s', a:message)
endfunction

"" Capture command
function! s:_capture(command) abort
  try
    let save_verbose = &verbose
    let &verbose = 0
    redir => out
    silent execute a:command
  finally
    redir END
    let &verbose = save_verbose
  endtry
  return out
endfunction

"" Capture command and return lines
function! s:_capture_lines(command) abort
  return split(s:_capture(a:command), "\n")
endfunction

"" Return funcname of script local functions with SID
function! s:_sfuncname(sid, funcname) abort
  return printf('<SNR>%s_%s', a:sid, a:funcname)
endfunction

function! s:_source(path) abort
  try
    execute ':source' fnameescape(a:path)
  catch /^Vim\%((\a\+)\)\=:E121:/
    " NOTE: workaround for `E121: Undefined variable: s:save_cpo`
    execute ':source' fnameescape(a:path)
  endtry
endfunction

let s:_cache = { '_': {} }

function! s:_cache.return(key, value) abort
  let self._[a:key] = a:value
  return a:value
endfunction

function! s:_cache.has(key) abort
  return has_key(self._, a:key)
endfunction

function! s:_cache.get(key) abort
  return self._[a:key]
endfunction

let s:cache = {
\ 'sid': deepcopy(s:_cache),
\ 'sid2path': deepcopy(s:_cache),
\ 'sid2svars': deepcopy(s:_cache)
\}

""" Main:

"" Improved scriptnames()
" @return {sid1: path1, sid2: path2, ...}
function! s:scriptnames() abort
  let sdict = {} " { sid: path }
  for line in s:_capture_lines(':scriptnames')
    let [sid, path] = split(line, '\m^\s*\d\+\zs:\s\ze')
    let sdict[str2nr(sid)] = s:_unify_path(path)  " str2nr(): '  1' -> 1
  endfor
  return sdict
endfunction

"" Return SID from the given path
" return -1 if the given path is not found in scriptnames()
" NOTE: it executes `:source` a given path once if the file hasn't sourced yet
function! s:sid(path) abort
  if s:cache.sid.has(a:path)
    return s:cache.sid.get(a:path)
  endif
  " Expand to full path
  let tp = fnamemodify(a:path, ':p') " target path
  " Relative to &runtimepath
  if !filereadable(tp)
    " NOTE: if there are more than one matched paths, use the first one.
    let tp = get(split(globpath(&runtimepath, a:path, 1), "\n"), 0, '')
  endif
  if !filereadable(tp)
    return s:_throw('file not found')
  endif
  let sid = s:_sid(tp, s:scriptnames())
  if sid isnot -1
    " return sid
    return s:cache.sid.return(a:path, sid)
  else
    call s:_source(tp)
    " return s:_sid(tp, s:scriptnames())
    return s:cache.sid.return(a:path, s:_sid(tp, s:scriptnames()))
  endif
endfunction

" Assume `a:abspath` is absolute path
function! s:_sid(abspath, scriptnames) abort
  " Handle symbolic link here
  let tp = s:_unify_path(a:abspath) " target path
  for sid in keys(a:scriptnames)
    if tp is# a:scriptnames[sid]
      return str2nr(sid)
    endif
  endfor
  return -1
endfunction

"" Return path from SID
function! s:sid2path(sid) abort
  if s:cache.sid2path.has(a:sid)
    return s:cache.sid2path.get(a:sid)
  endif
  let sn = s:scriptnames()
  if has_key(sn, a:sid)
    " return sn[a:sid]
    return s:cache.sid2path.return(a:sid, sn[a:sid])
  else
    return s:_throw('sid not found')
  endif
endfunction

"" Return a dict which contains script-local functions from given path
" `path` should be absolute path or relative to &runtimepath
" @return {funcname: funcref, funcname2: funcref2, ...}
" USAGE:
" :echo s:sfuncs('~/.vim/bundle/plugname/autoload/plugname.vim')
" " => { 'fname1': funcref1, 'fname2': funcref2, ...}
" :echo s:sfuncs('autoload/plugname.vim')
" " => { 'fname1': funcref1, 'fname2': funcref2, ...}
function! s:sfuncs(path) abort
  return s:sid2sfuncs(s:sid(a:path))
endfunction

"" Return a dict which contains script-local functions from SID
" USAGE:
" :echo s:sid2sfuncs(1)
" " => { 'fname1': funcref1, 'fname2': funcref2, ...}
" " The file whose SID is 1 may be your vimrc
" NOTE: old regexpengine has a bug which returns 0 with
" :echo "\<SNR>" =~# "\\%#=1\x80\xfdR"     | " => 0
" But it matches correctly with :h /collection
" :echo "\<SNR>" =~# "\\%#=1[\x80][\xfd]R" | " => 1
" http://lingr.com/room/vim/archives/2015/02/13#message-21261450
" In MS Windows with old Vim, [<binary>] doesn't work, but [\xXX] works well.
" The cause isn't being investigated.
let s:SNR = join(map(range(len("\<SNR>")), '"[\\x" . printf("%0x", char2nr("\<SNR>"[v:val])) . "]"'), '')
function! s:sid2sfuncs(sid) abort
  ":h :function /{pattern}
  " ->         ^________
  "    function <SNR>14_functionname(args, ...)
  let fs = s:_capture_lines(':function ' . printf('/^%s%s_', s:SNR, a:sid))
  let r = {}
  " ->         ^--------____________-
  "    function <SNR>14_functionname(args, ...)
  let pattern = printf('\m^function\s<SNR>%d_\zs\w\{-}\ze(', a:sid)
  for fname in map(fs, 'matchstr(v:val, pattern)')
    let r[fname] = function(s:_sfuncname(a:sid, fname))
  endfor
  return r
endfunction

let s:GETSVARSFUNCNAME = '___VITAL_VIM_SCRIPTLOCAL_GET_SVARS___'

let s:_get_svars_func = [
\   printf('function! s:%s() abort', s:GETSVARSFUNCNAME),
\          '    return s:',
\          'endfunction'
\ ]

"" Return script-local variable (s:var) dict form path
function! s:svars(path) abort
  return s:sid2svars(s:sid(a:path))
endfunction

"" Return script-local variable (s:var) dictionary form SID
function! s:sid2svars(sid) abort
  if s:cache.sid2svars.has(a:sid)
    return s:cache.sid2svars.get(a:sid)
  endif
  let fullpath = fnamemodify(s:sid2path(a:sid), ':p')
  let lines = readfile(fullpath)
  try
    call writefile(s:_get_svars_func, fullpath)
    call s:_source(fullpath)
    let sfuncname = s:_sfuncname(a:sid, s:GETSVARSFUNCNAME)
    let svars = call(function(sfuncname), [])
    execute 'delfunction' sfuncname
    " return svars
    return s:cache.sid2svars.return(a:sid, svars)
  finally
    call writefile(lines, fullpath)
  endtry
endfunction

function! s:_unify_path(path) abort
  return resolve(fnamemodify(a:path, ':p:gs?[\\/]?/?'))
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
