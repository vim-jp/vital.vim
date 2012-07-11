" simple buffer manager.

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V)
  let s:V = a:V
endfunction

let s:default_config = {
\   'range': 'tabpage',
\   'opener': 'split',
\ }
let s:Manager = {
\   '_config': s:default_config,
\   '_bufnrs': {},
\ }

function! s:Manager.open(bufname, ...)
  let result = {}
  let lastbuf = bufnr('$')
  let config = copy(self._config)
  if a:0
    call extend(config, s:_config(a:1))
  endif
  let moved = self.move(config.range)

  let Opener = moved ? 'edit' : config.opener
  while s:V.is_string(Opener) && Opener[0] ==# '='
    let Opener = eval(Opener[1 :])
  endwhile

  let loaded = s:open(a:bufname, Opener)
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

function! s:Manager.close(...)
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

function! s:Manager.opened(bufname)
endfunction

function! s:Manager.config(...)
  if a:0 == 2
    let self._config[a:1] = a:2
  elseif a:0 == 1
    if s:V.is_dict(a:1)
      call extend(self._config, a:1)
    else
      return get(self._config, a:1)
    endif
  elseif a:0 == 0
    return self._config
  endif
  return self
endfunction

function! s:Manager.is_managed(bufnr)
  return has_key(self._bufnrs, a:bufnr)
endfunction

function! s:Manager.add(bufnr, ...)
  let bufname = a:0 ? a:1 : bufname(a:bufnr)
  let self._bufnrs[a:bufnr] = bufname
endfunction

function! s:Manager.list()
  return sort(map(keys(self._bufnrs), 'v:val - 0'))
endfunction

function! s:Manager.nearest(...)
  let range = a:0 ? a:1 : self.config('range')

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

function! s:Manager.move(...)
  let range = a:0 ? a:1 : self.config('range')
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

function! s:Manager.do(cmd)
  let cmd = a:cmd =~ '%s' ? a:cmd : a:cmd . ' %s'
  for bufnr in self.list()
    execute substitute(cmd, '%s', bufnr, '')
  endfor
endfunction

function! s:new(...)
  return deepcopy(s:Manager).config(a:0 ? s:_config(a:1) : {})
endfunction

function! s:open(buffer, opener)
  if s:V.is_funcref(a:opener)
    let loaded = !bufloaded(a:buffer)
    call a:opener(a:bufname)
  elseif a:buffer is 0 || a:buffer is ''
    let loaded = 1
    silent execute a:opener
    enew
  else
    let loaded = !bufloaded(a:buffer)
    if s:V.is_string(a:buffer)
      execute a:opener '`=a:buffer`'
    elseif s:V.is_number(a:buffer)
      silent execute a:opener
      execute a:buffer 'buffer'
    else
      throw 'vital: Vim.Buffer.Manager: Unknown opener type.'
    endif
  endif
  return loaded
endfunction

function! s:_config(c)
  if s:V.is_dict(a:c)
    return a:c
  elseif s:V.is_string(a:c) || s:V.is_funcref(a:c)
    return {'opener': a:c}
  endif
  return {}
endfunction

function! s:_distance(a, b)
  return abs(a:a - s:base) - abs(a:b - s:base)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
