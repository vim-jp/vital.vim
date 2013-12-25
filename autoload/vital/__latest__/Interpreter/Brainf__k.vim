" Author: Tatsuhiro Ujihisa

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V)
  let s:V = a:V
endfunction

function! s:run(bfcode)
  call s:run_vim_parse_execute(a:bfcode)
endfunction

function! s:run_vim_parse_execute(bfcode)
  let [asts, rest] = s:_parse(a:bfcode)
  if rest !=# ''
    throw 'Vital.Interpreter.Brainf__k.run_vim_parse_execute(): parser failed to consume'
  endif
  call s:_execute(asts, 0, {})
endfunction

function! s:_parse(tokens)
  if a:tokens ==# ''
    return [[], '']
  endif

  let [t, tokens] = [a:tokens[0], a:tokens[1:]]

  if t ==# '['
    let [ast1, rest1] = s:_parse(tokens)
    let [ast2, rest2] = s:_parse(rest1)
    return [[ast1] + ast2, rest2]
  elseif t ==# ']'
    return [[], tokens]
  elseif t =~ '[+-><,\.]'
    let [asts, rest] = s:_parse(tokens)
    return [[t] + asts, rest]
  else
    return s:_parse(tokens)
  endif
endfunction

function! s:_execute(asts, pointer, tape)
  if len(a:asts) == 0
    return [a:pointer, a:tape]
  endif

  let [ast, asts] = [a:asts[0], a:asts[1:]]

  if s:V.is_list(ast)
    " echomsg string([a:tape, a:pointer, get(a:tape, a:pointer, 0)])
    if get(a:tape, a:pointer, 0) == 0
      return s:_execute(asts, a:pointer, a:tape)
    else
      let [pointer, tape] = s:_execute(ast, a:pointer, a:tape)
      return s:_execute(a:asts, pointer, tape)
    endif
  else
    if ast == '+'
      let a:tape[a:pointer] = get(a:tape, a:pointer, 0) + 1
      return s:_execute(asts, a:pointer, a:tape)
    elseif ast == '-'
      let a:tape[a:pointer] = get(a:tape, a:pointer, 0) - 1
      return s:_execute(asts, a:pointer, a:tape)
    elseif ast == '>'
      return s:_execute(asts, a:pointer + 1, a:tape)
    elseif ast == '<'
      return s:_execute(asts, a:pointer - 1, a:tape)
    elseif ast == '.'
      echon nr2char(get(a:tape, a:pointer, 0))
      return s:_execute(asts, a:pointer, a:tape)
    endif
  endif
endfunction

" let s:hello_world = "++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>."

let &cpo = s:save_cpo
unlet s:save_cpo
