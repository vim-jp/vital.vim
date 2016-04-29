local public = {lua = {}, vim = {}}
local P = _G[vim.eval('s:LuaP')].lua

function public.lua.lua_parse(tokens)
  if tokens == '' then
    return {}, ''
  end

  local t = string.sub(tokens, 1, 1)
  local tokens = string.sub(tokens, 2)

  if t == '[' then
    local ast1, rest1 = public.lua.lua_parse(tokens)
    local ast2, rest2 = public.lua.lua_parse(rest1)
    return P.cons(ast1, ast2), rest2
  elseif t == ']' then
    return {}, tokens
  else -- TODO
    local asts, rest = public.lua.lua_parse(tokens)
    return P.cons(t, asts), rest
  end
end

local _ = {}

function _.get(table, key, default)
  local x = table[key]
  if x then
    return x
  else
    return default
  end
end

function _.print_without_newline(str)
  -- TODO currently if_lua's io.write doesn't work as print since it's special
  vim.command(string.format('echon "%s"', str))
end

function public.lua.lua_execute(asts, pointer, tape)
  if #asts == 0 then
    return pointer, tape
  end
  local ast = asts[1]
  local asts = P.rest(asts)

  if type(ast) == "table" then
    if _.get(tape, pointer, 0) == 0 then
      return public.lua.lua_execute(asts, pointer, tape)
    else
      local pointer, tape = public.lua.lua_execute(ast, pointer, tape)
      return public.lua.lua_execute(P.cons(ast, asts), pointer, tape)
    end
  else
    if ast == '+' then
      tape[pointer] = _.get(tape, pointer, 0) + 1
      return public.lua.lua_execute(asts, pointer, tape)
    elseif ast == '-' then
      tape[pointer] = _.get(tape, pointer, 0) - 1
      return public.lua.lua_execute(asts, pointer, tape)
    elseif ast == '>' then
      return public.lua.lua_execute(asts, pointer + 1, tape)
    elseif ast == '<' then
      return public.lua.lua_execute(asts, pointer - 1, tape)
    elseif ast == '.' then
      _.print_without_newline(string.char(_.get(tape, pointer, 0)))
      return public.lua.lua_execute(asts, pointer, tape)
    else
      return public.lua.lua_execute(asts, pointer, tape)
    end
  end
end

function public.vim.lua_parse(tokens)
  local asts, rest = public.lua.lua_parse(tokens)
  return P.from_lua({asts, rest})
end

function public.vim.lua_execute(asts, pointer, tape)
  local tape = P.to_lua(tape)
  local asts = P.to_lua(asts)
  local pointer, tape = public.lua.lua_execute(asts, pointer, tape)
  return P.from_lua({pointer, tape})
end

_G[vital_context] = public
