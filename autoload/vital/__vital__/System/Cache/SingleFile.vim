let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:Base = a:V.import('System.Cache.Base')
  let s:File = a:V.import('System.Cache.File')
  let s:Memory = a:V.import('System.Cache.Memory')
endfunction
function! s:_vital_depends() abort
  return ['System.Cache.Base', 'System.Cache.File', 'System.Cache.Memory']
endfunction

let s:cache = {
      \ '__name__': 'singlefile',
      \}
function! s:new(...) abort
  let options = extend({
        \ 'cache_file': '',
        \ 'autodump': 1,
        \}, get(a:000, 0, {})
        \)
  if empty(options.cache_file)
    throw 'vital: System.Cache.SingleFile: "cache_file" option is empty.'
  endif
  " create a cache directory if it does not exist
  let cache_dir = fnamemodify(options.cache_file, ':p:h')
  if !isdirectory(cache_dir)
    call mkdir(cache_dir, 'p')
  endif
  let cache = extend(
        \ call(s:Base.new, a:000, s:Base),
        \ extend(options, deepcopy(s:cache))
        \)
  " Add internal cache system
  let cache._memory = s:Memory.new()
  let cache._memory.__parent__ = cache
  function! cache._memory.on_changed() abort
    if self.__parent__.autodump
      call self.__parent__.dump()
    endif
  endfunction
  " Load cache
  call cache.load()
  return cache
endfunction

function! s:cache.load() abort
  if filereadable(self.cache_file)
    let obj = s:File.load(self.cache_file, {})
    if type(obj) == type({})
      let self._memory._cached = obj
      call self.on_changed()
    endif
  endif
endfunction
function! s:cache.dump() abort
  call s:File.dump(self.cache_file, self._memory._cached)
endfunction

function! s:cache.has(name) abort
  return self._memory.has(a:name)
endfunction
function! s:cache.get(name, ...) abort
  let default = get(a:000, 0, '')
  return self._memory.get(a:name, default)
endfunction
function! s:cache.set(name, value) abort
  call self._memory.set(a:name, a:value)
  call self.on_changed()
endfunction
function! s:cache.remove(name) abort
  if self._memory.has(a:name)
    call self._memory.remove(a:name)
    call self.on_changed()
  endif
endfunction
function! s:cache.keys() abort
  return self._memory.keys()
endfunction
function! s:cache.clear() abort
  call self._memory.clear()
  call self.on_changed()
endfunction

let &cpo = s:save_cpo
unlet! s:save_cpo
" vim:set et ts=2 sts=2 sw=2 tw=0 fdm=marker:
