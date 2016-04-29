" very simple message localization library.

let s:save_cpo = &cpo
set cpo&vim

function! s:new(path) abort
  let obj = copy(s:Message)
  let obj.path = a:path =~# '%s' ? a:path : 'message/' . a:path . '/%s.txt'
  return obj
endfunction

function! s:get_lang() abort
  return v:lang ==# 'C' ? 'en' : v:lang[: 1]
endfunction

let s:Message = {}
function! s:Message.get(text) abort
  if !has_key(self, 'lang')
    call self.load(s:get_lang())
  endif
  if has_key(self.data, a:text)
    return self.data[a:text]
  endif
  let text = self.missing(a:text)
  return type(text) == type('') ? text : a:text
endfunction
function! s:Message.load(lang) abort
  let pattern = printf(self.path, a:lang)
  let files = split(globpath(&runtimepath, pattern), "\n")
  let data = {}
  for file in files
    if filereadable(file)
      let lines = filter(readfile(file), 'v:val !~# "^\\s*#"')
      sandbox let res = eval(iconv(join(lines, ''), 'utf-8', &encoding))
      if type(res) == type(data)
        call extend(data, res)
      endif
      unlet res
    endif
  endfor
  let self.lang = a:lang
  let self.data = data
endfunction
let s:Message._ = s:Message.get
function! s:Message.missing(text) abort
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
