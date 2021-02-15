let s:suite = themis#suite('help')

function! s:suite.after() abort
  if filereadable('doc/tags')
    call delete('doc/tags')
  endif
endfunction

function! s:suite.make_helptags() abort
  " Detect E154
  helptags doc
endfunction

function! s:suite.__modules__() abort
  let modules = themis#suite('helptags for module')

  function! modules.before() abort
    helptags doc
  endfunction

  function! modules.__each_modules__() abort
    let t_func = type(function('type'))
    let V = vital#vital#new()
    for module_name in V.search('**')
      if module_name =~# '^\%(Deprecated\|Experimental\)\.'
        continue
      endif
      let module = V.import(module_name)
      let suite = themis#suite(module_name)
      for member_name in keys(module)
        let args = type(module[member_name]) == t_func ? '()' : ''
        let tagname = printf('Vital.%s.%s%s', module_name, member_name, args)
        execute join([
        \   printf('function! suite.%s()', member_name),
        \   printf('  help %s', tagname),
        \   'endfunction',
        \ ], "\n")
      endfor
    endfor
  endfunction
endfunction
