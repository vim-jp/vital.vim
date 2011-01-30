let s:vital = {'version': '__latest__'}

" Check vimproc."{{{
try
  let s:exists_vimproc_version = vimproc#version()
catch
  let s:exists_vimproc_version = 0
endtry
"}}}
function! s:vital.has_vimproc()"{{{
  return s:exists_vimproc_version
endfunction"}}}
function! s:vital.system(str, ...)"{{{
  let l:command = a:str
  let l:input = a:0 >= 1 ? a:1 : ''
  if &termencoding != '' && &termencoding != &encoding
    let l:command = iconv(l:command, &encoding, &termencoding)
    let l:input = iconv(l:input, &encoding, &termencoding)
  endif

  if a:0 == 0
    let l:output = s:vital.has_vimproc() ?
          \ vimproc#system(l:command) : system(l:command)
  else
    let l:output = s:vital.has_vimproc() ?
          \ vimproc#system(l:command, l:input) : system(l:command, l:input)
  endif

  if &termencoding != '' && &termencoding != &encoding
    let l:output = iconv(l:output, &termencoding, &encoding)
  endif

  return l:output
endfunction"}}}
function! s:vital.get_last_status()"{{{
  return s:vital.has_vimproc() ?
        \ vimproc#get_last_status() : v:shell_error
endfunction"}}}
function! vital#__latest__#new()"{{{
  return s:vital
endfunction"}}}
" vim: foldmethod=marker
