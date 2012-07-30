" vitalizer by vim script.

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
let s:changes_file = s:vital_dir . '/Changes'

function! s:check_system()
  if !executable('git')
    throw 'vitalizer: git is required by vitalizer.'
  endif
  if !isdirectory(s:git_dir)
    throw 'vitalizer: vital directory must be a git work directory.'
  endif
endfunction
function! s:git(cmd)
  return system(printf('git --git-dir "%s" %s', s:git_dir, a:cmd))
endfunction
function! s:git_current_hash()
  return s:git('rev-parse HEAD')
endfunction
function! s:git_checkout(hash)
  return s:git('checkout ' . hash)
endfunction
function! s:copy(from, to)
  let todir = substitute(s:FP.dirname(a:to), '//', '/', 'g')
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
  return filter(map(split(glob(s:vital_dir . '/autoload/vital/**/*.vim', 1), "\n"),
  \          'matchstr(s:FP.unify_separator(v:val), pat)'), 'v:val!=""')
endfunction
function! s:get_changes()
  if !filereadable(s:changes_file)
    return {}
  endif
  let sections = split(join(readfile(s:changes_file), "\n"), '\n\ze[a-z0-9]\{7}\n')
  let changes = {}
  for section in sections
    let lines = split(section, "\n")
    let changes[lines[0]] = join(
    \  map(lines[1:], 'matchstr(v:val, "^\\s*\\zs.*")'), "\n")
  endfor
  return changes
endfunction
function! s:show_changes(vital_file)
  let [ver] = readfile(a:vital_file, 'b', 1)
  let current = substitute(ver, '\W', '', 'g')
  let confirm_required = 0
  if current != '_latest__'
    let keys = split(s:git(printf("log --format=format:%%h %s..HEAD", current)), "\n")
    let changes = s:get_changes()
    for key in keys
      if has_key(changes, key)
        echomsg key
        echomsg join(map(split(changes[key], "\n"), '"    ".v:val'))
        let confirm_required = 1
      endif
    endfor
  endif
  return confirm_required
endfunction
function! vitalizer#vitalize(name, to, modules, hash)
  " FIXME: Should check if a working tree is dirty.

  " Save current HEAD to restore a working tree later.
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

  try
    " Search *.vital file in a target directory.
    let vital_file = a:to . '/autoload/vital/' . a:name . '.vital'
    let filelist = glob(a:to . '/autoload/vital/*.vital', 1)
    if !filereadable(vital_file) && filelist != ''
      let vital_file = split(filelist, '\n')[0]
    endif

    " Determine installing modules.
    let all_modules = []
    if filereadable(vital_file)
      let all_modules = readfile(vital_file)[2 :]
    endif
    if !empty(a:modules)
      let [diff, modules] = s:L.partition('v:val =~# "^[+-]"', a:modules)
      if !empty(modules)
        let all_modules = modules
      endif
      for entry in diff
        let module = entry[1 :]
        if entry[0] ==# '+'
          let all_modules += [module]
        else
          call filter(all_modules, 'v:val !=# module')
        endif
      endfor
    endif
    if empty(all_modules)
      let files = s:all_modules()
    else
      let all_modules = s:L.uniq(all_modules)
      let files = map(s:search_dependence(all_modules + s:REQUIRED_MODULES),
      \               's:module2file(v:val)')
    endif

    " Show critical changes.
    " (like 'apt-listchanges' in Debian, or 'eselect news' in Gentoo)
    " TODO: Support changes in a limit range by passing 'hash' value.
    if filereadable(vital_file) && s:show_changes(vital_file)
      echohl WarningMsg
      echomsg "*** WARNING *** There are critical changes from previous vital you installed."
      echohl None
      if confirm("Would you like to install a new version?", "&Y\n&n", "Y")
        echomsg "Canceled"
        return
      endif
    endif

    " Remove previous vital.
    if isdirectory(a:to . '/autoload/vital')
      call s:F.rmdir(a:to . '/autoload/vital', 'rf')
    endif
    if filereadable(a:to . '/autoload/vital.vim')
      call delete(a:to . '/autoload/vital.vim')
    endif

    " Install vital.
    let short_hash = hash[: s:HASH_SIZE]
    for f in files + s:REQUIRED_FILES
      let after = substitute(f, '__latest__', '_' . short_hash, '')
      call s:copy(s:vital_dir . '/' . f, a:to . '/' . after)
    endfor
    call writefile([short_hash, ''] + all_modules, vital_file)
  finally
    " Go back to HEAD if previously checked-out.
    if exists('cur')
      call s:git_checkout(cur)
    endif
  endtry
endfunction
function! vitalizer#complete(arglead, cmdline, cursorpos)
  let options = ['--init', '--name=', '--hash=', '--help']
  let args = filter(split(a:cmdline[: a:cursorpos], '[^\\]\zs\s\+'), 'v:val!~"^--"')
  if a:arglead =~ '^--'
    return filter(options, 'stridx(v:val, a:arglead)!=-1')
  elseif len(args) > 2 || (len(args) == 2 && a:cmdline =~# '\s$')
    let prefix = a:arglead =~# '^[+-]' ? a:arglead[0] : ''
    return filter(map(s:all_modules(), 'prefix . s:file2module(v:val)'),
    \  'stridx(v:val, a:arglead)!=-1')
  else
    return map(filter(split(glob(a:arglead . "*", 1), "\n"),
    \  'isdirectory(v:val)'), 'escape(v:val, " ")')
  endif
endfunction
function! vitalizer#command(args)
  call s:check_system()
  let options = filter(copy(a:args), 'v:val=~"^--"')
  let args = filter(copy(a:args), 'v:val!~"^--"')
  if empty(args)
    call insert(options, '--help')
  else
    let to = fnamemodify(args[0], ':p')
    let modules = args[1 :]
    let name = fnamemodify(to, ':h:t')
  endif
  let hash = ''
  for option in options
    if option =~ '^--init'
      let modules = filter(map(s:all_modules(), 's:file2module(v:val)'),
      \  'v:val!=""')
    elseif option =~ '^--help'
      echo "Usage :Vitalize [options ...] {target-dir} [module ...]"
      return
    elseif option =~ '^--name=\S'
      let name = option[7:]
    elseif option =~ '^--hash=\S'
      let hash = option[7:]
    else
      echohl Error | echomsg "Invalid argument: ".option | echohl None
      return
    endif
  endfor
  if len(args) == 0
    echohl Error | echomsg "Argument required" | echohl None
    return
  endif
  call vitalizer#vitalize(name, to, modules, hash)
endfunction

let &cpo = s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
