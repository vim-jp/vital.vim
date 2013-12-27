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

function public.vim.lua_parse(tokens)
  local asts, rest = public.lua.lua_parse(tokens)
  return P.from_lua({asts, rest})
end

_G[vital_context] = public
