" vitalizer in vim script.

let s:save_cpo = &cpo
set cpo&vim

let s:REQUIRED_FILES = [
\   'autoload/vital.vim',
\   'autoload/vital/__latest__.vim',
\ ]
let s:HASH_SIZE = 6
let s:V = vital#of('vital')
let s:L = s:V.import('Data.List')
let s:F = s:V.import('System.File')
let s:FP = s:V.import('System.Filepath')
let s:Mes = s:V.import('Vim.Message')

let g:vitalizer#vital_dir =
\     get(g:, 'vitalizer#vital_dir', expand('<sfile>:h:h:p'))

function! s:git_dir() abort
  return s:FP.join(g:vitalizer#vital_dir, '.git')
endfunction

function! s:check_system() abort
  if !executable('git')
    throw 'vitalizer: git is required by vitalizer.'
  endif
  let git_dir = s:git_dir()
  " NOTE: git_dir is a file with recent git
  " when vital.vim repository is a submodule.
  if !isdirectory(git_dir) && !filereadable(git_dir)
    throw 'vitalizer: vital directory must be a git work directory.'
  endif
endfunction

function! s:git(cmd) abort
  let cmd = printf('git --git-dir "%s" %s', s:git_dir(), a:cmd)
  let output = system(cmd)
  if v:shell_error
    throw "vitalizer: '" . cmd . "' failed: ".output
  endif
  return output
endfunction

function! s:git_hash(rev) abort
  return s:git('rev-parse ' . a:rev)
endfunction

function! s:git_checkout(hash) abort
  try
    return s:git('checkout ' . a:hash)
  catch
    throw "vitalizer: 'git checkout' failed: " . v:exception
  endtry
endfunction

function! s:copy(from, to) abort
  let todir = substitute(s:FP.dirname(a:to), '//', '/', 'g')
  if !isdirectory(todir)
    call mkdir(todir, 'p')
  endif
  let convert_newline = 'substitute(v:val, "\\r$", "", "")'
  call writefile(map(readfile(a:from, "b"), convert_newline), a:to, "b")
endfunction

function! s:search_dependence(depends_info) abort
  " XXX Not smart...
  if exists('g:vital_debug')
    let vital_debug = g:vital_debug
  endif
  let g:vital_debug = 1
  call s:V.unload()
  let all = {}
  let entries = copy(a:depends_info)
  while !empty(entries)
    call s:L.sort_by(entries, 'type(v:val) == type([]) ? len(v:val) : 0')
    unlet! entry
    let entry = remove(entries, 0)

    let modules = s:V.expand_modules(entry, all)

    for module in modules
      let M = s:V.import(module, 1)
      if has_key(M, '_vital_depends')
        call extend(entries, M._vital_depends())
      endif
    endfor
  endwhile
  if exists('vital_debug')
    let g:vital_debug = vital_debug
  endif
  return sort(keys(all))
endfunction

function! s:is_camel_case(str) abort
  return !empty(matchstr(a:str, '^\%([0-9A-Z]\l*\)\+$'))
endfunction

function! s:is_module_name(str) abort
  return s:L.and(map(split(a:str, '\.'), 's:is_camel_case(v:val)'))
endfunction

function! s:module2file(name) abort
  let target = a:name ==# '' ? '' : '/' . substitute(a:name, '\W\+', '/', 'g')
  return printf('autoload/vital/__latest__%s.vim', target)
endfunction

function! s:file2module(file) abort
  let filename = s:FP.unify_separator(a:file)
  let tail = matchstr(filename, 'autoload/vital/_\w\+/\zs.*\ze\.vim$')
  return join(split(tail, '[\\/]\+'), '.')
endfunction

function! s:available_module_names() abort
  return sort(s:L.uniq(filter(map(split(globpath(&runtimepath,
  \          'autoload/vital/__latest__/**/*.vim', 1), "\n"),
  \          's:file2module(v:val)'), 's:is_module_name(v:val)')))
endfunction

function! s:get_changes() abort
  let changes_file = s:FP.join(g:vitalizer#vital_dir, 'Changes')
  if !filereadable(changes_file)
    return {}
  endif
  let sections = split(join(readfile(changes_file), "\n"), '\n\ze[a-z0-9]\+\n')
  let changes = {}
  for section in sections
    let lines = split(section, "\n")
    let text = join(
    \  map(lines[1:], 'matchstr(v:val, "^\\s*\\zs.*")'), "\n")
    let [modules, text] = matchlist(text, '\%(Modules:\s*\([^\n]\+\)\n\)\?\(.\+\)')[1:2]
    if text ==# ''
      throw 'vitalizer: parse error in Changes file'
    endif
    " If "Modules: *" is specified, or "Modules: ..." line is
    " not specified, show the change always.
    let modules = modules ==# '*' ? '' : modules
    let changes[lines[0]] = {'text': text, 'modules': split(modules, '[^[:alnum:].]\+')}
  endfor
  return changes
endfunction

function! s:show_changes(current, installing_modules) abort
  let confirm_required = 0
  if a:current != '_latest__'
    let keys = split(s:git(printf("log --format=format:%%h %s..HEAD", a:current)), "\n")
    let changes = s:get_changes()
    for key in keys
      if has_key(changes, key)
      \ && (empty(changes[key].modules)
      \ || s:L.has_common_items(changes[key].modules, a:installing_modules))
        echohl None
        echomsg key
        if empty(changes[key].modules)
          echomsg '    Modules: *'
        else
          " Show the only installed modules in specified one
          let common = string(s:L.intersect(changes[key].modules, a:installing_modules))
          let common = substitute(common,"'", "", "g")
          let common = substitute(common,"[", "", "g")
          let common = substitute(common,"]", "", "g")
          echomsg '    Modules: '.common
        endif
        for line in split(changes[key].text, "\n")
          if line =~# '^\*\*.*\*\*$'
            let mes = '    ' . matchstr(line, '^\*\*\s*\zs.\{-}\ze\s*\*\*$')
            call s:Mes.echomsg('SpellBad', mes)
          else
            echomsg '    '.line
          endif
        endfor
        let confirm_required = 1
        echohl None
      endif
    endfor
  endif
  return confirm_required
endfunction

" Uninstall vital from {target-dir}.
function! s:uninstall(target_dir) abort
  if isdirectory(a:target_dir . '/autoload/vital')
    call s:F.rmdir(a:target_dir . '/autoload/vital', 'rf')
  endif
  if filereadable(a:target_dir . '/autoload/vital.vim')
    call delete(a:target_dir . '/autoload/vital.vim')
  endif
endfunction

" Search *.vital file in a target directory.
function! s:search_old_vital_file(to) abort
  let filelist = split(glob(a:to . '/autoload/vital/*.vital', 1), "\n")
  return len(filelist) == 1 ? filelist[0] : ''
endfunction

function! s:build_vital_data(to, name) abort
  let name = a:name
  let hash = ''
  let modules = []

  let old_vital_file = s:search_old_vital_file(a:to)
  if filereadable(old_vital_file)
    let lines = readfile(old_vital_file)
    let [head, modules] = s:L.break('v:val ==# ""', lines)
    if 2 <= len(head) && empty(name)
      let name = head[0]
    endif
    let hash = head[-1]
    let modules = modules[1 :]
  endif
  if empty(name)
    let name = s:FP.basename(a:to)
  endif
  let vital_file = s:FP.join(a:to, 'autoload', 'vital', name . '.vital')
  return {
  \   'name': name,
  \   'vital_file': vital_file,
  \   'hash': hash,
  \   'modules': modules,
  \ }
endfunction

function! vitalizer#vitalize(name, to, modules, hash) abort
  " FIXME: Should check if a working tree is dirty.

  " Check arguments
  if !isdirectory(a:to)
    throw 'vitalizer: {target-dir} must exist.'
  endif

  let need_checkout = !empty(a:hash)
  let rev = need_checkout ? a:hash : 'HEAD'
  try
    let hash = s:git_hash(rev)
  catch
    throw 'vitalizer: Could not retrieve target revision: ' . v:exception
  endtry

  if need_checkout
    call s:git_checkout(hash)
  endif

  try
    let vital_data = s:build_vital_data(a:to, a:name)

    if empty(vital_data.name)
      throw 'vitalizer: {name} must not be empty.'
    endif
    if vital_data.name !~# '^\w\+$'
      throw 'vitalizer: {name} can contain only alphabets, numbers, or underscore.'
    endif

    " Check if all of specified modules exist.
    let missing = copy(a:modules)
    call map(missing, 'substitute(v:val, "^[+-]", "", "")')
    let all_modules = s:available_module_names()
    call filter(missing, 'index(all_modules, v:val) is -1')
    if !empty(missing)
      throw "vitalizer: Some modules don't exist: " . join(missing, ', ')
    endif

    " Determine installing modules.
    let installing_modules = copy(vital_data.modules)
    if !empty(a:modules)
      let [diff, modules] = s:L.partition('v:val =~# "^[+-]"', a:modules)
      if !empty(modules)
        let installing_modules = modules
      endif
      for entry in diff
        let module = entry[1 :]
        if entry[0] ==# '+'
          let installing_modules += [module]
        else
          call filter(installing_modules, 'v:val !=# module')
        endif
      endfor
    endif
    let initial_install = !isdirectory(s:FP.join(a:to, 'autoload', 'vital'))
    if empty(installing_modules) && !initial_install
      if confirm("vitalizer: Are you sure you want to uninstall vital?", "&Yes\n&No") == 2
        return {
        \ 'action': 'canceled',
        \ 'prev_hash': '',
        \ 'installed_hash': '',
        \}
      endif
      let action = 'uninstall'
      let files = []
    else
      let action = 'install'
      let installing_modules = s:L.uniq(installing_modules)
      let files = map(s:search_dependence(installing_modules),
      \               's:module2file(v:val)')
    endif

    " Show critical changes.
    " (like 'apt-listchanges' in Debian, or 'eselect news' in Gentoo)
    " TODO: Support changes in a limit range by passing 'hash' value.
    if !empty(vital_data.hash) &&
    \   s:show_changes(vital_data.hash, installing_modules)
      call s:Mes.warn('*** WARNING *** There are critical changes from previous vital you installed.')
      if confirm("Would you like to install a new version?", "&Y\n&n", 1) !=# 1
        echomsg "Canceled"
        return {}
      endif
    endif

    " List and check the installing files.
    let install_files = []
    for f in files + s:REQUIRED_FILES
      let after = substitute(f, '__latest__', '_' . vital_data.name, '')
      let paths = globpath(g:vitalizer#vital_dir . ',' . &runtimepath, f, 1)
      let from = get(split(paths, "\n"), 0)
      if !filereadable(from)
        throw 'vitalizer: Can not read the installing file: ' . from
      endif
      call add(install_files, [from, s:FP.join(a:to, after)])
    endfor

    " Remove previous vital.
    call s:uninstall(a:to)

    if action ==# 'install'
      " Install vital.
      let short_hash = hash[: s:HASH_SIZE]
      for [from, to] in install_files
        call s:copy(from, to)
      endfor
      let content = [vital_data.name, short_hash, ''] + installing_modules
      call writefile(content, vital_data.vital_file)

      return {
      \ 'action': 'install',
      \ 'prev_hash': vital_data.hash,
      \ 'installed_hash': short_hash,
      \}
    elseif action ==# 'uninstall'
      " Uninstall vital.
      " Do nothing already removed.
      return {
      \ 'action': 'uninstall',
      \ 'prev_hash': '',
      \ 'installed_hash': '',
      \}
    else
      throw 'vitalizer: Internal error, unknown action'
    endif

  finally
    " Restore the HEAD
    if need_checkout
      call s:git_checkout('-')
    endif
  endtry
endfunction

function! vitalizer#complete(arglead, cmdline, cursorpos) abort
  let options = ['--name=', '--hash=', '--help']
  let args = filter(split(a:cmdline[: a:cursorpos], '[^\\]\zs\s\+'), 'v:val!~"^--"')
  if a:arglead =~ '^--'
    return filter(options, 'stridx(v:val, a:arglead)!=-1')
  elseif len(args) > 2 || (len(args) == 2 && a:cmdline =~# '\s$')
    let prefix = a:arglead =~# '^[+-]' ? a:arglead[0] : ''
    return filter(map(s:available_module_names(), 'prefix . v:val'),
    \  'stridx(v:val, a:arglead)!=-1')
  else
    let pattern = a:arglead
    let pattern .= isdirectory(a:arglead) ? s:FP.separator() : ''
    return map(filter(split(glob(pattern . "*", 1), "\n"),
    \  'isdirectory(v:val)'), 'escape(v:val, " ")')
  endif
endfunction

function! vitalizer#command(args) abort
  try
    call s:check_system()
  catch
    call s:Mes.error(v:exception)
    return
  endtry
  let options = filter(copy(a:args), 'v:val=~"^--"')
  let args = filter(copy(a:args), 'v:val!~"^--"')
  let to = ''
  let modules = []
  let name = ''
  if empty(args)
    call insert(options, '--help')
  else
    let to = fnamemodify(args[0], ':p')
    let modules = args[1 :]
  endif
  let hash = ''
  for option in options
    if option =~ '^--help'
      echo "Usage :Vitalize [options ...] {target-dir} [module ...]"
      return
    elseif option =~ '^--name=\S'
      let name = option[7:]
    elseif option =~ '^--hash=\S'
      let hash = option[7:]
    else
      call s:Mes.error("Invalid argument: " . option)
      return
    endif
  endfor
  if len(args) == 0
    call s:Mes.error("Argument required")
    return
  endif
  try
    let result = vitalizer#vitalize(name, to, modules, hash)
    if !empty(result) && result.action ==# 'install'
      if result.prev_hash ==# ''
        let mes = printf("vitalizer: installed vital to '%s'. (%s)",
        \                to, result.installed_hash)
      else
        let hash_stat = result.prev_hash . '->' . result.installed_hash
        let mes = printf("vitalizer: updated vital of '%s'. (%s)",
        \                to, hash_stat)
      endif
      call s:Mes.echomsg('MoreMsg', mes)
    elseif !empty(result) && result.action ==# 'uninstall'
      call s:Mes.echomsg('MoreMsg', "vitalizer: uninstalled vital. You can specify the name on next time.")
    endif
  catch /^vitalizer:/
    call s:Mes.error(v:exception)
  endtry
endfunction

let &cpo = s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
