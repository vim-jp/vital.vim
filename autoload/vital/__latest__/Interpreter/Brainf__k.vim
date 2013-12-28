" Author: Tatsuhiro Ujihisa

let s:save_cpo = &cpo
set cpo&vim

let s:sfile = expand('<sfile>:p')

function! s:_vital_loaded(V)
  let s:V = a:V

  if has('lua')
    let s:P = s:V.import('Experimental.Lua.Prelude')
    let s:LuaP = s:P.lua_namespace()

    execute printf('lua vital_context = "%s"', s:sfile)
    call luaeval('dofile(_A)', substitute(s:sfile, '.vim$', '.lua', ''))
  endif
endfunction

function! s:_vital_depends()
  if has('lua')
    return ['Experimental.Lua.Prelude']
  else
    return []
  endif
endfunction

function! s:run(bfcode)
  call s:run_vim_parse_execute(a:bfcode)
endfunction

function! s:run_vim_parse_execute(bfcode)
  let [asts, rest] = s:_vim_parse(a:bfcode)
  if rest !=# ''
    throw 'Vital.Interpreter.Brainf__k.run_vim_parse_execute(): parser failed to consume'
  endif
  call s:_vim_execute(asts, 0, {})
endfunction

function s:run_lua_parse_execute(bfcode)
  let [asts, rest] =  s:_lua_parse(a:bfcode)
  if rest !=# ''
    throw 'Vital.Interpreter.Brainf__k.run_vim_parse_execute(): parser failed to consume'
  endif
  call s:_lua_execute(asts, 0, {})
endfunction

function! s:_vim_parse(tokens)
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
  elseif t =~ '[+-><,\.]'
    let [asts, rest] = s:_vim_parse(tokens)
    return [[t] + asts, rest]
  else
    return s:_vim_parse(tokens)
  endif
endfunction

function! s:_lua_parse(bfcode)
  return luaeval('_G[_A[0]].vim.lua_parse(_A[1])', [s:sfile, a:bfcode])
endfunction

" args:
"   asts: a list of parsed ASTs
"   pointer: where to refer in tape (give 0 when you start)
"   tape: storage for BF (give {} when you start)
" return: [pointer, tape]
"   the final state of pointer and tape to continue if you have more ASTs that
"   you didn't pass to the call.
function! s:_vim_execute(asts, pointer, tape)
  let [asts, pointer, tape] = [a:asts, a:pointer, a:tape]
  while len(asts) > 0
    unlet! ast
    let [ast, asts] = [asts[0], asts[1:]]

    if s:V.is_list(ast)
      if get(tape, pointer, 0) == 0
        " go next
      else
        let [pointer, tape] = s:_vim_execute(ast, pointer, tape)
        let asts = [ast] + asts
      endif
    else
      if ast == '+'
        let tape[pointer] = get(tape, pointer, 0) + 1
      elseif ast == '-'
        let tape[pointer] = get(tape, pointer, 0) - 1
      elseif ast == '>'
        let pointer += 1
      elseif ast == '<'
        let pointer -= 1
      elseif ast == '.'
        echon nr2char(get(tape, pointer, 0))
      endif
    endif
  endwhile
  return [pointer, tape]
endfunction

function! s:_lua_execute(asts, pointer, tape)
  return luaeval('_G[_A[0]].vim.lua_execute(_A[1], _A[2], _A[3])', [s:sfile, a:asts, a:pointer, a:tape])
endfunction

" let s:hello_world = "++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>."

let &cpo = s:save_cpo
unlet s:save_cpo
