local public = {lua = {}, vim = {}}
local P = _G[vim.eval('s:LuaP')].lua

function public.lua.lua_parse(bfcode)
  TODO
end

function public.vim.lua_parse(bfcode)
  return P.from_lua(public.lua.lua_parse(bfcode))
end

_G[vital_context] = public
