" Author: Tatsuhiro Ujihisa

let s:save_cpo = &cpo
set cpo&vim

let s:sfile = expand('<sfile>:p')

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Prelude = s:V.import('Prelude')

  if has('lua')
    let s:P = s:V.import('Deprecated.Lua.Prelude')
    let s:LuaP = s:P.lua_namespace()

    execute printf('lua vital_context = "%s"', escape(s:sfile, '\'))
    if has('patch-8.1.0672')
      call luaeval('nil,dofile(_A)', substitute(s:sfile, '.vim$', '.lua', ''))
    else
      call luaeval('0,dofile(_A)', substitute(s:sfile, '.vim$', '.lua', ''))
    endif
  endif
endfunction

function! s:_vital_depends() abort
  return ['Prelude']
  \    + (has('lua') ? ['Deprecated.Lua.Prelude'] : [])
endfunction

function! s:run(bfcode) abort
  call s:run_vim_parse_execute(a:bfcode)
endfunction

function! s:run_vim_parse_execute(bfcode) abort
  let [asts, rest] = s:_vim_parse(a:bfcode)
  if rest !=# ''
    throw 'vital: Interpreter.Brainf__k: run_vim_parse_execute(): parser failed to consume'
  endif
  call s:_vim_execute(asts, 0, {})
endfunction

function! s:run_lua_parse_execute(bfcode) abort
  let [asts, rest] =  s:_lua_parse(a:bfcode)
  if rest !=# ''
    throw 'vital: Interpreter.Brainf__k: run_vim_parse_execute(): parser failed to consume'
  endif
  call s:_lua_execute(asts, 0, {})
endfunction

function! s:_vim_parse(tokens) abort
  if a:tokens ==# ''
    return [[], '']
  endif

  let [t, tokens] = [a:tokens[0], a:tokens[1:]]

  if t ==# '['
    let [ast1, rest1] = s:_vim_parse(tokens)
    let [ast2, rest2] = s:_vim_parse(rest1)
    return [[ast1] + ast2, rest2]
  elseif t ==# ']'
    return [[], tokens]
  elseif t =~# '[+-><,\.]'
    let [asts, rest] = s:_vim_parse(tokens)
    return [[t] + asts, rest]
  else
    return s:_vim_parse(tokens)
  endif
endfunction

function! s:_lua_parse(bfcode) abort
  return luaeval('_G[_A[0]].vim.lua_parse(_A[1])', [s:sfile, a:bfcode])
endfunction

" args:
"   asts: a list of parsed ASTs
"   pointer: where to refer in tape (give 0 when you start)
"   tape: storage for BF (give {} when you start)
" return: [pointer, tape]
"   the final state of pointer and tape to continue if you have more ASTs that
"   you didn't pass to the call.
function! s:_vim_execute(asts, pointer, tape) abort
  let [asts, pointer, tape] = [a:asts, a:pointer, a:tape]
  while len(asts) > 0
    unlet! ast
    let [ast, asts] = [asts[0], asts[1:]]

    if s:Prelude.is_list(ast)
      if get(tape, pointer, 0) == 0
        " go next
      else
        let [pointer, tape] = s:_vim_execute(ast, pointer, tape)
        let asts = [ast] + asts
      endif
    else
      if ast ==# '+'
        let tape[pointer] = get(tape, pointer, 0) + 1
      elseif ast ==# '-'
        let tape[pointer] = get(tape, pointer, 0) - 1
      elseif ast ==# '>'
        let pointer += 1
      elseif ast ==# '<'
        let pointer -= 1
      elseif ast ==# '.'
        echon nr2char(get(tape, pointer, 0))
      endif
    endif
  endwhile
  return [pointer, tape]
endfunction

function! s:_lua_execute(asts, pointer, tape) abort
  return luaeval('_G[_A[0]].vim.lua_execute(_A[1], _A[2], _A[3])', [s:sfile, a:asts, a:pointer, a:tape])
endfunction

" let s:hello_world = "++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>."

let &cpo = s:save_cpo
unlet s:save_cpo
