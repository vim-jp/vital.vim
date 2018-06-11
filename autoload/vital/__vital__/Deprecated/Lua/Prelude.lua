-- Lua.Prelude
-- Author: Tatsuhiro Ujihisa

local public = {lua = {}, vim = {}}

function public.lua.plus(x, y)
  return x + y
end

public.vim.plus = public.lua.plus

function public.lua.map(list, f)
  local memo = {}
  for _, v in ipairs(list) do
    table.insert(memo, f(v))
  end
  return memo
end

local is_list = function(tbl)
  -- http://stackoverflow.com/questions/6077006/how-can-i-check-if-a-lua-table-contains-only-sequential-numeric-indices
  local numKeys = 0
  for _, _ in pairs(tbl) do
    numKeys = numKeys + 1
  end
  local numIndices = 0
  for _, _ in ipairs(tbl) do
    numIndices = numIndices + 1
  end
  return numKeys == numIndices
end

function public.lua.to_lua(vobj)
  if vim.type(vobj) == 'list' then
    local memo = {}
    for v in vobj() do
      table.insert(memo, public.lua.to_lua(v))
    end
    return memo
  elseif vim.type(vobj) == 'dict' then
    local memo = {}
    for k, v in vobj() do
      memo[k] = public.lua.to_lua(v)
    end
    return memo
  else
    return vobj
  end
end

local lualist2vimlist = function(lualist)
  local memo = vim.list()
  for _, v in ipairs(lualist) do
    memo:add(public.lua.from_lua(v))
  end
  return memo
end

local luadict2vimdict = function(luadict)
  local memo = vim.dict()
  for k, v in pairs(luadict) do
    memo[k] = public.lua.from_lua(v)
  end
  return memo
end

function public.lua.from_lua(x)
  if type(x) == "table" then
    if is_list(x) then
      return lualist2vimlist(x)
    else
      return luadict2vimdict(x)
    end
  else
    return x
  end
end

-- function public.vim.map(list, f)
--   return public.lua.from_lua(public.lua.map(public.lua.to_lua(list), f))
-- end

-- only for lua
function public.lua.rest(array, index)
  -- TODO Deprecated.Text.Sexp also has one
  index = index or 2
  local rest = {}
  for i = index, #array do
    rest[#rest + 1] = array[i]
  end
  return rest
end

-- only for lua
function public.lua.cons(x, xs)
  -- TODO Deprecated.Text.Sexp also has one
  local memo = {x}
  for _, v in ipairs(xs) do
    table.insert(memo, v)
  end
  return memo
end

_G[vital_context] = public
