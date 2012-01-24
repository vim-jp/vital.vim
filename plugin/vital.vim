" vitalizer by vim script.

if exists('g:loaded_vital')
  finish
endif
let g:loaded_vital = 1

let s:save_cpo = &cpo
set cpo&vim

let s:REQUIRED_FILES = [
\   'autoload/vital.vim',
\   'autoload/vital/__latest__.vim',
\ ]
let s:REQUIRED_MODULES = [
\   'Prelude',
\ ]
let s:HASH_SIZE = 6
let s:V = vital#of('vital')
let s:L = s:V.import('Data.List')
let s:F = s:V.import('System.File')
let s:FP = s:V.import('System.Filepath')
let s:vital_dir = expand('<sfile>:h:h:p')
let s:git_dir = s:vital_dir . '/.git'

function! s:check_system()
  if !executable('git')
    throw 'vital: git is required by vitalizer.'
  endif
  if !isdirectory(s:git_dir)
    throw 'vital: vital directory must be a git work directory.'
  endif
endfunction
function! s:git(cmd)
  return system(printf('git --git-dir %s %s', shellescape(s:git_dir), a:cmd))
endfunction
function! s:git_current_hash()
  return s:git('rev-parse HEAD')
endfunction
function! s:git_checkout(hash)
  return s:git('co ' . hash)
endfunction
function! s:copy(from, to)
  let todir = s:FP.dirname(a:to)
  if !isdirectory(todir)
    call mkdir(todir, 'p')
  endif
  call writefile(readfile(a:from, "b"), a:to, "b")
endfunction
function! s:search_dependence(modules)
  call s:V.unload()
  let all = {}
  let modules = a:modules
  while !empty(modules)
    let next = []
    for module in modules
      if has_key(all, module)
        continue
      endif
      let M = s:V.import(module, 1)
      let all[module] = 1
      if has_key(M, '_vital_depends')
        call extend(next, M._vital_depends())
      endif
    endfor
    let modules = next
  endwhile
  return sort(keys(all))
endfunction
function! s:module2file(name)
  let target = a:name ==# '' ? '' : '/' . substitute(a:name, '\W\+', '/', 'g')
  let target = substitute(target, '\l\zs\ze\u', '_', 'g')
  let target = substitute(target, '[/_]\zs\u', '\l\0', 'g')
  return printf('autoload/vital/__latest__%s.vim', target)
endfunction
function! s:camelize(str)
  return substitute(a:str, '\%(^\|_\)\(\l\)', '\u\1', 'g')
endfunction
function! s:file2module(file)
  let tail = matchstr(a:file, 'autoload/vital/_\w\+/\zs.*\ze\.vim$')
  return join(map(split(tail, '[\\/]\+'), 's:camelize(v:val)'), '.')
endfunction
function! s:all_modules()
  let pat = '^.*\zs\<autoload/vital/.*'
  return filter(map(split(glob(s:vital_dir . '/autoload/vital/**/*.vim'), "\n"),
  \          'matchstr(substitute(v:val, "\\", "/", "g"), pat)'), 'v:val!=""')
endfunction
function! s:vitalize(name, to, modules, hash)
  let cur = s:git_current_hash()
  if a:hash ==# ''
    let hash = cur
    unlet cur
  elseif cur !=? a:hash
    call s:git_checkout(a:hash)
    let hash = a:hash
  else
    unlet cur
  endif
  let vital_file = a:to . '/autoload/vital/' . a:name . '.vital'
  if !empty(a:modules)
    let all_modules = a:modules + s:REQUIRED_MODULES
  elseif filereadable(vital_file)
    let all_modules = readfile(vital_file)[2 :]
  else
    let all_modules = []
  endif
  let all_modules = s:L.uniq(all_modules)
  if empty(all_modules)
    let files = s:all_modules()
  else
    let files = map(s:search_dependence(all_modules), 's:module2file(v:val)')
  endif
  if isdirectory(a:to . '/autoload/vital')
    call s:F.rmdir(a:to . '/autoload/vital', 'rf')
  endif
  if filereadable(a:to . '/autoload/vital.vim')
    call delete(a:to . '/autoload/vital.vim')
  endif
  let shash = hash[: s:HASH_SIZE]
  for f in files + s:REQUIRED_FILES
    let after = substitute(f, '__latest__', '_' . shash, '')
    call s:copy(s:vital_dir . '/' . f, a:to . '/' . after)
  endfor
  call writefile([shash, ''] + all_modules, vital_file)
  if exists('cur')
    call s:git_checkout(cur)
  endif
endfunction
function! s:command(args)
  call s:check_system()
  let options = filter(copy(a:args), 'v:val=~"^--"')
  let args = filter(copy(a:args), 'v:val!~"^--"')
  let to = ''
  let modules = args[1:]
  let name = fnamemodify(to, ':h:t')
  let hash = ''
  for option in options
    if option =~ '^--init'
      let modules = filter(map(s:all_modules(), 's:file2module(v:val)'),
      \  'v:val!=""')
    elseif option =~ '^--help'
      echo "Usage :Vitalize {options} {target-dir} [module ...]"
      return
    elseif option =~ '^--name=\S'
      let name = option[7:]
    elseif option =~ '^--hash=\S'
      let hash = option[7:]
    else
      echohl Error | echomsg "Invalid argument" | echohl None
      return
    endif
  endfor
  if len(args) == 0
    echohl Error | echomsg "Argument required" | echohl None
    return
  endif
  let to = fnamemodify(args[0], ':p')
  call s:vitalize(name, to, modules, '')
endfunction

" :Vitalize {options} {target-dir} [module ...]
command! -nargs=* Vitalize call s:command([<f-args>])

let &cpo = s:save_cpo
unlet s:save_cpo
