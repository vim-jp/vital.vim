" buffer manager.

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_depends() abort
  return ['Prelude', 'Vim.Buffer']
endfunction

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:P = s:V.import('Prelude')
  let s:B = s:V.import('Vim.Buffer')
endfunction

let s:default_config = {
\   'range': 'tabpage',
\   'opener': 'split',
\ }
let s:Manager = {
\   '_config': s:default_config,
\   '_user_config': {},
\   '_bufnrs': {},
\ }

function! s:Manager.open(bufname, ...) abort
  if s:B.is_cmdwin()
    " Note: Failed to open buffer in cmdline window.
    return {
  \   'loaded': 0,
  \   'newwin': -1,
  \   'newbuf': 0,
  \   'bufnr': -1,
  \ }
  endif

  let lastbuf = bufnr('$')
  let config = s:_make_config(self, a:000)
  let moved = self.move(config.range)

  let Opener = moved ? 'edit' : config.opener
  while s:P.is_string(Opener) && Opener[0] ==# '='
    let Opener = eval(Opener[1 :])
  endwhile

  let loaded = s:B.open(a:bufname, Opener)
  let new_bufnr = bufnr('%')
  let self._bufnrs[new_bufnr] = a:bufname

  call self.opened(a:bufname)
  return {
  \   'loaded': loaded,
  \   'newwin': moved,
  \   'newbuf': lastbuf < bufnr('%'),
  \   'bufnr': new_bufnr,
  \ }
endfunction

function! s:Manager.close(...) abort
  if call(self.move, a:000, self)
    if winnr('$') != 1
      close
    elseif tabpagenr('$') != 1
      tabclose
    else
      enew
    endif
  endif
endfunction

function! s:Manager.opened(bufname) abort
endfunction

function! s:Manager.config(...) abort
  if a:0 == 0
    return self._config
  elseif a:0 == 1 && s:P.is_dict(a:1)
    call extend(self._config, a:1)
    return self
  elseif a:0 == 1
    return get(self._config, a:1)
  elseif a:0 == 2
    let self._config[a:1] = a:2
    return self
  endif
  throw 'Vital.Vim.BufferManager: invalid argument for config()'
endfunction

function! s:Manager.user_config(config) abort
  let self._user_config = a:config
  return self
endfunction

function! s:Manager.is_managed(bufnr) abort
  return has_key(self._bufnrs, a:bufnr)
endfunction

function! s:Manager.add(bufnr, ...) abort
  let bufname = a:0 ? a:1 : bufname(a:bufnr)
  let self._bufnrs[a:bufnr] = bufname
endfunction

function! s:Manager.list() abort
  return sort(map(keys(self._bufnrs), 'v:val - 0'))
endfunction

function! s:Manager.nearest(...) abort
  let range = s:_make_config(self, map(copy(a:000), '{"range": v:val}')).range

  if range ==# 'tabpage'
    let tabpages = [tabpagenr()]
  else
    let s:base = tabpagenr()
    let tabpages = sort(range(1, tabpagenr('$')), 's:_distance')
  endif

  for tabnr in tabpages
    let s:base = tabpagewinnr(tabnr)
    let buflist = tabpagebuflist(tabnr)
    for winnr in sort(range(1, len(buflist)), 's:_distance')
      if self.is_managed(buflist[winnr - 1])
        return [tabnr, winnr, buflist[winnr - 1]]
      endif
    endfor
  endfor
  return []
endfunction

function! s:Manager.move(...) abort
  let range = s:_make_config(self, map(copy(a:000), '{"range": v:val}')).range
  if range !=# 'all' && range !=# 'tabpage'
    return 0
  endif
  let near = self.nearest(range)
  if empty(near)
    return 0
  endif
  silent execute 'tabnext' near[0]
  silent execute near[1] 'wincmd w'
  return 1
endfunction

function! s:Manager.do(cmd) abort
  let cmd =
        \ a:cmd =~ '%s' ? a:cmd
        \               : a:cmd . ' %s'
  for bufnr in self.list()
    execute substitute(cmd, '%s', bufnr, '')
  endfor
endfunction

function! s:new(...) abort
  return deepcopy(s:Manager)
  \.config(a:0 ? s:_config(a:1) : {})
  \.user_config(2 <= a:0 ? a:2 : {})
endfunction

function! s:open(buffer, opener) abort
  call s:_deprecated("open")
  return s:B.open(a:buffer, a:opener)
endfunction

function! s:_deprecated(fname) abort
  echomsg printf("Vital.Vim.BufferManager.%s is deprecated! Please use Vital.Vim.Buffer.%s instead.",
        \ a:fname, a:fname)
endfunction

function! s:is_cmdwin() abort
  call s:_deprecated("is_cmdwin")
  return s:B.is_cmdwin()
endfunction

function! s:_make_config(manager, configs) abort
  let configs = [a:manager._config]
  let user = a:manager._user_config
  if s:P.is_string(user)
    let configs += [exists(user) ? {user} : {}]
  elseif s:P.is_dict(user)
    let configs += [map(copy(user), 'exists(v:val) ? {v:val} : {}')]
  endif

  let config = {}
  for c in configs + a:configs
    call extend(config, s:_config(c))
  endfor
  return config
endfunction

function! s:_config(c) abort
  if s:P.is_dict(a:c)
    return a:c
  elseif s:P.is_string(a:c) || s:P.is_funcref(a:c)
    return {'opener': a:c}
  endif
  return {}
endfunction

function! s:_distance(a, b) abort
  return abs(a:a - s:base) - abs(a:b - s:base)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
