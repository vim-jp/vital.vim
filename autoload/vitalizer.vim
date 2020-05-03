" vitalizer in vim script.

let s:save_cpo = &cpo
set cpo&vim

let s:LOADER_FILES = [
\   'autoload/vital/vital.vim',
\   'autoload/vital/_vital.vim',
\ ]
let s:V = vital#vital#new()
let s:P = s:V.import('Prelude')
let s:L = s:V.import('Data.List')
let s:S = s:V.import('Data.String')
let s:F = s:V.import('System.File')
let s:FP = s:V.import('System.Filepath')
let s:Mes = s:V.import('Vim.Message')
let s:Dict = s:V.import('Data.Dict')
let s:I = s:V.import('Data.String.Interpolation')

let g:vitalizer#vital_dir =
\     get(g:, 'vitalizer#vital_dir', expand('<sfile>:h:h:p'))

let s:DATA_DIR = s:FP.join(g:vitalizer#vital_dir, 'data', 'vital')
" Insert s:AUTOLOADABLIZE_TEMPLATE to each module files:)
let s:AUTOLOADABLIZE_TEMPLATE = readfile(s:FP.join(s:DATA_DIR, 'autoloadablize.vim'))

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
  let cmd = printf('git --git-dir "%s" --work-tree "%s" %s', s:git_dir(), g:vitalizer#vital_dir, a:cmd)
  let output = system(cmd)
  if v:shell_error
    throw "vitalizer: '" . cmd . "' failed: ".output
  endif
  return output
endfunction

function! s:git_hash(rev) abort
  return s:S.chomp(s:git('rev-parse ' . a:rev))
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
  call writefile(map(readfile(a:from, 'b'), convert_newline), a:to, 'b')
endfunction

function! s:rmdir(dir) abort
  if isdirectory(a:dir)
    call s:F.rmdir(a:dir, 'rf')
  endif
endfunction

function! s:rmdir_if_empty(dir) abort
  if isdirectory(a:dir)
    try
      call s:F.rmdir(a:dir)
    catch
    endtry
  endif
endfunction

function! s:rmfile(file) abort
  if filereadable(a:file)
    call delete(a:file)
  endif
endfunction


" s:get_all_modules() returns all modules(<raw-module>) and files.
" It gathers all dependencies of each module of given module_names.
" <raw-module> has all script local function of the module.
" a:to is for get builtin modules.
" @return { 'modules': list<raw-module>, 'files': list<module-path> }
function! s:get_all_modules(module_names, to) abort
  let all_modules = {}
  let all_files = {}
  let data_files = []
  let entries = copy(a:module_names)

  let builtin_modules = s:builtin_modules(a:to)
  for module_name in builtin_modules
    let module = s:get_module(module_name)
    let all_modules[module_name] = module
    " Ignore dfiles because it is builtin
    let dmodules = s:get_dependence(module_name, module)[0]
    let all_files[module_name] = 1
    let entries += dmodules
  endfor

  while !empty(entries)
    call s:L.sort_by(entries, 'type(v:val) == type([]) ? len(v:val) : 0')
    unlet! entry
    let entry = remove(entries, 0)

    let modules = s:expand_modules(s:V, entry, all_files)

    for module_name in modules
      let module = s:get_module(module_name)
      let all_modules[module_name] = module
      let [dmodules, dfiles] = s:get_dependence(module_name, module)
      let entries += dmodules
      let data_files += dfiles
    endfor
  endwhile

  for module_name in builtin_modules
    call remove(all_files, module_name)
  endfor

  return {
  \   'modules': all_modules,
  \   'files': sort(map(keys(all_files), 's:module2file(v:val)') + data_files),
  \ }
endfunction

function! s:get_module(module_name) abort
  return s:V._get_module(a:module_name)
endfunction

" @param {vital-object} V
" @param {module-name} module_name
" @param {module} module object
" @return [list<{module-name}>, list<{data-file}>]
function! s:get_dependence(module_name, module) abort
  if !has_key(a:module, '_vital_depends')
    return [[], []]
  endif
  let depends = a:module._vital_depends()
  if s:P.is_dict(depends)
    let dmodules = get(depends, 'modules', [])
    let dfiles = get(depends, 'files', [])
  elseif s:P.is_list(depends)
    let [dmodules, dfiles] = s:L.partition('v:val[0] !=# "."', depends)
  else
    throw printf('vitalizer: %s has wrong dependence.(%s)',
    \            a:module_name, string(depends))
  endif
  if !empty(dfiles)
    let module_file = s:module2file(a:module_name)
    let module_base = s:FP.dirname(module_file)
    call map(dfiles, 's:FP.join(module_base, v:val)')
    call map(dfiles, 'simplify(v:val)')
  endif
  return [dmodules, dfiles]
endfunction

function! s:expand_modules(V, entry, all) abort
  if type(a:entry) == type([])
    let candidates = s:L.concat(map(copy(a:entry), 'a:V.search(v:val)'))
    if empty(candidates)
      throw printf('vital: Any of module %s is not found', string(a:entry))
    endif
    if eval(join(map(copy(candidates), 'has_key(a:all, v:val)'), '+'))
      let modules = []
    else
      let modules = [candidates[0]]
    endif
  else
    let modules = a:V.search(a:entry)
    if empty(modules)
      throw printf('vital: Module %s is not found', a:entry)
    endif
  endif
  call filter(modules, '!has_key(a:all, v:val)')
  for module in modules
    let a:all[module] = 1
  endfor
  return modules
endfunction

function! s:is_camel_case(str) abort
  return !empty(matchstr(a:str, '^\%([0-9A-Z]\l*\)\+$'))
endfunction

function! s:is_module_name(str) abort
  return s:L.and(map(split(a:str, '\.'), 's:is_camel_case(v:val)'))
endfunction

" s:module2file() returns relative path of module to &runtimepath.
" Note that {plugin-name} in returned path will be `vital`.
" @param {module-name} name
" @return {rtp-relative-path}
function! s:module2file(name) abort
  let target = a:name ==# '' ? '' : '/' . substitute(a:name, '\W\+', '/', 'g')
  return printf('autoload/vital/__vital__%s.vim', target)
endfunction

" @param {path} file
" @return {module-name}
function! s:file2module_name(file) abort
  let filename = s:FP.unify_separator(a:file)
  let tail = matchstr(filename, 'autoload/vital/_\w\+/\zs.*\ze\.vim$')
  return join(split(tail, '[\\/]\+'), '.')
endfunction

" @return list<{module-name}>
function! s:available_module_names() abort
  return s:V.search('**')
endfunction

function! s:builtin_modules(rtp_dir) abort
  let pat = s:FP.join(a:rtp_dir, 'autoload/vital/__*__/**/*.vim')
  let files = split(glob(pat, 1), "\n")
  return map(files, 's:file2module_name(v:val)')
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
    " not specified, always show the change.
    let modules = modules ==# '*' ? '' : modules
    let changes[lines[0]] = {'text': text, 'modules': split(modules, '[^[:alnum:].]\+')}
  endfor
  return changes
endfunction

function! s:show_changes(current, installing_modules) abort
  let confirm_required = 0
  if a:current !=# 'vital'
    let keys = split(s:git(printf('log --format=format:%%H %s..HEAD', a:current)), "\n")
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
          let common = s:L.intersect(changes[key].modules, a:installing_modules)
          echomsg '    Modules: ' . join(common, ', ')
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
function! s:uninstall(target_dir, name) abort
  let base = s:FP.join(a:target_dir, 'autoload', 'vital')
  call s:rmdir(s:FP.join(base, '_' . a:name))
  call s:rmfile(s:FP.join(base, '_' . a:name . '.vim'))
  call s:rmfile(s:FP.join(base, a:name . '.vital'))
  call s:rmdir_if_empty(base)
  call s:rmfile(s:FP.join(a:target_dir, 'autoload', 'vital.vim'))
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

" @return {list<[from, to]>}
function! s:install_module_files(module_files, plugin_name, to) abort
  " List and check the installing module_files.
  let install_files = []
  for f in a:module_files
    let after = substitute(f, '_\?_vital\(__\)\?', '_' . a:plugin_name, '')
    let after = substitute(after, 'vital/\zsvital\ze\.vim$', a:plugin_name, '')
    let pat = substitute(f, '__vital__', '__*__', '')
    let paths = globpath(g:vitalizer#vital_dir . ',' . &runtimepath, pat, 1)
    let from = get(split(paths, "\n"), 0)
    if !filereadable(from)
      throw 'vitalizer: Can not read the installing file: ' . from
    endif
    call add(install_files, [from, s:FP.join(a:to, after)])
  endfor
  return install_files
endfunction

" @return {list<[from, to]>}
function! s:loader_files(plugin_name, to) abort
  let loader_files = []
  for f in s:LOADER_FILES
    let from = s:FP.join(g:vitalizer#vital_dir, f)
    if !filereadable(from)
      throw 'vitalizer: Can not read a loader file: ' . from
    endif
    let after = substitute(f, 'vital/_\?\zsvital\ze\.vim$', a:plugin_name, '')
    call add(loader_files, [from, s:FP.join(a:to, after)])
  endfor
  return loader_files
endfunction

" s:autoloadablize() makes a module to be called by autoload function.
function! s:autoloadablize(module_file, plugin_name, raw_module) abort
  let module_name = s:file2module_name(a:module_file)
  let data = s:autoloadablize_data(module_name, a:raw_module, a:plugin_name)
  let save_module_lines = readfile(a:module_file)
  let lines = split(s:I.interpolate(join(s:AUTOLOADABLIZE_TEMPLATE, "\n"), data), "\n") + save_module_lines
  call writefile(lines, a:module_file)
endfunction

function! s:autoloadablize_data(module_name, raw_module, plugin_name) abort
  let functions = s:filter_module_funcs(a:raw_module)
  " Create funcdict which key is function name and value is empty string.
  " map() values to create Funcref in template file.
  let funcdict = {}
  for funcname in functions
    let funcdict[funcname] = ''
  endfor
  return {
  \   'autoload_import': s:autoload_import(a:plugin_name, a:module_name),
  \   'funcdict': string(funcdict),
  \   'plugin_name': a:plugin_name,
  \ }
endfunction

function! s:autoload_import(plugin_name, module_name) abort
  return printf('vital#_%s#%s#import', a:plugin_name, substitute(a:module_name, '\.', '#', 'g'))
endfunction

" It doesn't need to filter functions here because Vital.import() will
" filter them after calling module._vital_loaded() and module._vital_created().
" However, this line collects functions here including module._vital_*() to
" reduce the size of autoloadablize code.
" sort(functions) not to generate unneeded diff.
function! s:filter_module_funcs(raw_module) abort
  return sort(keys(filter(a:raw_module, 'v:key =~# "^\\a" || v:key =~# "^_vital_"')))
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
    let save_rtp = &runtimepath
    let &runtimepath = a:to . ',' . &runtimepath
    call s:V.unload()

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
    let all_module_names = s:available_module_names()
    call filter(missing, 'index(all_module_names, v:val) is -1')
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
    let action = 'install'  " TODO: We need --uninstall option
    let installing_modules = s:L.uniq(installing_modules)
    let all_modules_data = s:get_all_modules(installing_modules, a:to)
    let module_files = all_modules_data.files
    let all_modules = all_modules_data.modules

    " Show critical changes.
    " (like 'apt-listchanges' in Debian, or 'eselect news' in Gentoo)
    " TODO: Support changes in a limit range by passing 'hash' value.
    if !empty(vital_data.hash) &&
    \   s:show_changes(vital_data.hash, installing_modules)
      call s:Mes.warn('*** WARNING *** There are critical changes from previous vital you installed.')
      if confirm('Would you like to install a new version?', "&Y\n&n", 1) !=# 1
        echomsg 'Canceled'
        return {}
      endif
    endif

    " Remove previous vital.
    call s:uninstall(a:to, vital_data.name)

    if action ==# 'install'
      " Install loader
      for [from, to] in s:loader_files(vital_data.name, a:to)
        call s:copy(from, to)
      endfor

      " Install modules.
      for [from, to] in s:install_module_files(module_files, vital_data.name, a:to)
        call s:copy(from, to)
        " .vim is module file/otherwise data file
        " module file need autoloadablize process
        if fnamemodify(to, ':e') ==# 'vim'
          let module_name = s:file2module_name(to)
          if has_key(all_modules, module_name)
            call s:autoloadablize(to, vital_data.name, all_modules[module_name])
          endif
        endif
      endfor
      let content = [vital_data.name, hash, ''] + installing_modules
      call writefile(content, vital_data.vital_file)

      return {
      \ 'action': 'install',
      \ 'prev_hash': vital_data.hash,
      \ 'installed_hash': hash,
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
    let &runtimepath = save_rtp
    " Restore the HEAD
    if need_checkout
      call s:git_checkout('-')
    endif
  endtry
endfunction

function! vitalizer#complete(arglead, cmdline, cursorpos) abort
  let options = ['--name=', '--hash=', '--help']
  let args = filter(split(a:cmdline[: a:cursorpos], '[^\\]\zs\s\+'), 'v:val !~# "^--"')
  if a:arglead =~# '^--'
    return filter(options, 'stridx(v:val, a:arglead)!=-1')
  elseif len(args) > 2 || (len(args) == 2 && a:cmdline =~# '\s$')
    let prefix = a:arglead =~# '^[+-]' ? a:arglead[0] : ''
    return filter(map(s:available_module_names(), 'prefix . v:val'),
    \  'stridx(v:val, a:arglead)!=-1')
  else
    let pattern = a:arglead
    let pattern .= isdirectory(a:arglead) ? s:FP.separator() : ''
    return map(filter(split(glob(pattern . '*', 1), "\n"),
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
  let options = filter(copy(a:args), 'v:val =~# "^--"')
  let args = filter(copy(a:args), 'v:val !~# "^--"')
  let to = ''
  let modules = []
  let name = ''
  if empty(args)
    call insert(options, '--help')
  else
    let to = fnamemodify(expand(args[0]), ':p')
    let modules = args[1 :]
  endif
  let hash = ''
  for option in options
    if option =~# '^--help'
      echo 'Usage :Vitalize [options ...] {target-dir} [module ...]'
      return
    elseif option =~# '^--name=\S'
      let name = option[7:]
    elseif option =~# '^--hash=\S'
      let hash = option[7:]
    else
      call s:Mes.error('Invalid argument: ' . option)
      return
    endif
  endfor
  if len(args) == 0
    call s:Mes.error('Argument required')
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
      call s:Mes.echomsg('MoreMsg', 'vitalizer: uninstalled vital. You can specify the name on next time.')
    endif
  catch /^vitalizer:/
    call s:Mes.error(v:exception)
  endtry
endfunction

let &cpo = s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
