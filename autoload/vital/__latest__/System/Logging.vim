let s:save_cpo = &cpo
set cpo&vim

let s:NOTSET   = -1
let s:DEBUG    = 0
let s:INFO     = 1
let s:WARNING  = 2
let s:ERROR    = 3
let s:CRITICAL = 4
let s:LEVELS   = ['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL']

let s:sfile          = expand('<sfile>')
let s:config         = {}
let s:default_config = {}

let s:logger         = {}

function! s:logger.get_logfile() abort
  if has_key(self, '__logfile__')
    return self.__logfile__
  else
    return self.__parent__.get_logfile()
  endif
endfunction

function! s:logger.set_logfile(...) abort
  let logfile = get(a:000, 0, '')
  if empty(logfile)
    if self.__name__ ==# '.'
      let self.__logfile__ = s:get_default_logfile()
    else
      silent! unlet! self.__logfile__
    endif
  else
    let self.__logfile__ = logfile
  endif
endfunction

function! s:logger.get_loglevel() abort
  if has_key(self, '__loglevel__')
    return self.__loglevel__
  else
    return self.__parent__.get_loglevel()
  endif
endfunction

function! s:logger.set_loglevel(...) abort
  let loglevel = get(a:000, 0, s:NOTSET)
  if loglevel == s:NOTSET
    if self.__name__ ==# '.'
      let self.__loglevel__ = s:WARNING
    else
      silent! unlet! self.__loglevel__
    endif
  else
    let self.__loglevel__ = loglevel
  endif
endfunction

function! s:logger.is_enabled_for(loglevel) abort
  return self.get_loglevel() <= a:loglevel
endfunction

function! s:logger.format(loglevel, fmt, ...) abort
  return printf('%s;%s;%s; %s',
        \ strftime('%Y-%m-%d %H:%M:%S'),
        \ self.__name__,
        \ s:LEVELS[a:loglevel],
        \ len(a:000) ? call('printf', extend([a:fmt], a:000)) : a:fmt,
        \)
endfunction

function! s:logger.emit(record) abort
  let fname = self.get_logfile()
  let dirname = fnamemodify(fname, ':h')
  if !isdirectory(dirname)
    call mkdir(dirname, 'p')
  endif
  call s:F.writefile(
        \ split(a:record, '\v\r?\n'),
        \ fname,
        \ 'a',
        \)
endfunction

function! s:logger.log(loglevel, fmt, ...) abort
  if !self.is_enabled_for(a:loglevel)
    return
  endif
  let record = call(self.format, extend([a:loglevel, a:fmt], a:000), self)
  call self.emit(record)
endfunction

function! s:logger.debug(fmt, ...) abort
  call call(self.log, extend([s:DEBUG, a:fmt], a:000), self)
endfunction
function! s:logger.info(fmt, ...) abort
  call call(self.log, extend([s:INFO, a:fmt], a:000), self)
endfunction
function! s:logger.warning(fmt, ...) abort
  call call(self.log, extend([s:WARNING, a:fmt], a:000), self)
endfunction
function! s:logger.error(fmt, ...) abort
  call call(self.log, extend([s:ERROR, a:fmt], a:000), self)
endfunction
function! s:logger.critical(fmt, ...) abort
  call call(self.log, extend([s:CRITICAL, a:fmt], a:000), self)
endfunction
function! s:logger.exception(fmt, ...) abort
  call call(self.log, extend([s:ERROR, a:fmt], a:000), self)
  call call(self.log, extend([
        \   s:ERROR,
        \   'Exception: "%s" in %s',
        \   v:exception,
        \   v:throwpoint
        \ ], a:000), self)
endfunction

function! s:_vital_loaded(V) dict abort
  let s:V = a:V
  let s:D = a:V.import('Data.Dict')
  let s:F = a:V.import('System.File')
  let s:P = a:V.import('System.Filepath')
  let s:C = a:V.import('System.Cache.Memory').new()
  " Export several variables
  let self.NOTSET   = s:NOTSET
  let self.DEBUG    = s:DEBUG
  let self.INFO     = s:INFO
  let self.WARNING  = s:WARNING
  let self.ERROR    = s:ERROR
  let self.CRITICAL = s:CRITICAL
  let self.LEVELS   = s:LEVELS
  " Configure settings
  let s:separator = s:P.separator()
  let s:default_config = {
        \ 'basename': s:get_default_basename(),
        \}
  let s:config = deepcopy(s:default_config)
  " Create a root logger
  let logger = s:_new('.', s:logger)
  let logger.NOTSET   = s:NOTSET
  let logger.DEBUG    = s:DEBUG
  let logger.INFO     = s:INFO
  let logger.WARNING  = s:WARNING
  let logger.ERROR    = s:ERROR
  let logger.CRITICAL = s:CRITICAL
  let logger.LEVELS   = s:LEVELS
  call logger.set_logfile()
  call logger.set_loglevel()
endfunction

function! s:_vital_depends() abort
  return [
        \ 'Data.Dict',
        \ 'System.File',
        \ 'System.Filepath',
        \ 'System.Cache.Memory',
        \]
endfunction

function! s:get_default_logfile() abort
  let name = substitute(
        \ fnamemodify(s:sfile, ':h:h:t'),
        \ '^_', '', '',
        \)
  " TODO Consider about Windows
  if empty($XDG_CONFIG_HOME)
    let config_home = s:P.join(expand('~'), '.' . name)
  else
    let config_home = s:P.join($XDG_CONFIG_HOME, name)
  endif
  return s:P.join(config_home, 'logger.log')
endfunction

function! s:get_default_basename() abort
  return fnamemodify(s:sfile, ':p:h:h:h:h')
endfunction

function! s:get_config() abort
  return deepcopy(s:config)
endfunction

function! s:set_config(...) abort
  let config = get(a:000, 0, s:default_config)
  let s:config = extend(
        \ s:config,
        \ s:D.pick(config, keys(s:default_config)),
        \)
endfunction

function! s:get_name(name) abort
  if fnamemodify(a:name, ':p') =~# printf('^%s', s:config.basename)
    let name = substitute(
          \ fnamemodify(a:name, ':p'),
          \ printf('^%s%s\?', s:config.basename, s:separator),
          \ '', '',
          \)
  else
    let name = a:name
  endif
  return empty(name) ? '.' : name
endfunction

function! s:_new(name, parent)
  let base = s:D.omit(a:parent, [
        \ '__logfile__',
        \ '__loglevel__',
        \])
  let logger = extend(base, {
        \ '__name__': a:name,
        \ '__parent__': a:parent,
        \})
  lockvar 1 logger.__name__
  lockvar 1 logger.__parent__
  call s:C.set(a:name, logger)
  return logger
endfunction

function! s:of(...)
  let name = s:get_name(get(a:000, 0, '.'))
  if s:C.has(name)
    return s:C.get(name)
  endif
  let parent = s:of(fnamemodify(name, ':h'))
  return s:_new(name, parent)
endfunction


let &cpo = s:save_cpo
" vim:set et ts=2 sts=2 sw=2 tw=0 fdm=marker:
