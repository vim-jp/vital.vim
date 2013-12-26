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

" args:
"   asts: a list of parsed ASTs
"   pointer: where to refer in tape (give 0 when you start)
"   tape: storage for BF (give {} when you start)
" return: [pointer, tape]
"   the final state of pointer and tape to continue if you have more ASTs that
"   you didn't pass to the call.
function! s:_execute(asts, pointer, tape)
  let [asts, pointer, tape] = [a:asts, a:pointer, a:tape]
  while len(asts) > 0
    unlet! ast
    let [ast, asts] = [asts[0], asts[1:]]

    if s:V.is_list(ast)
      if get(tape, pointer, 0) == 0
        " go next
      else
        let [pointer, tape] = s:_execute(ast, pointer, tape)
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

" let s:hello_world = "++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>."

let &cpo = s:save_cpo
unlet s:save_cpo
