-- Lua.Prelude
-- Author: Tatsuhiro Ujihisa

local public = {lua = {}, vim = {}}
local _ = {}

local P = _G[vim.eval('s:LuaP')].lua

function _.cons(x, xs)
  local memo = {x}
  for _, v in ipairs(xs) do
    table.insert(memo, v)
  end
  return memo
end

local find_one = function(str, patterns, idx)
  for _, labelpattern in ipairs(patterns) do
    local label = labelpattern[1]
    local pattern = labelpattern[2]

    local matched = str:match('^' .. pattern, idx)
    if matched then
      return label, matched
    end
  end
end

-- local size_iterator = function(iter)
--   local i = 0
--   for _ in iter do
--     i = i + 1
--   end
--   return i
-- end

function public.lua.tokenize(lex_rule, sexp)
  -- for x in sexp:gmatch('[%(%)]') do
  --   print("ok", x)
  -- end
  local tokens = {}
  local col = 1
  -- local row = 1
  while true do
    local label, matched = find_one(sexp, lex_rule, col)
    if not label then
      break
    end
    table.insert(tokens, {col = col, label = label, matched_text = matched})
    col = col + #matched
    -- row = row + size_iterator(matched:gmatch("\n"))
  end
  return tokens
end

function public.lua.parse_progress(tokens, parse_rules, context)
  if #tokens == 0 then
    return {}, ""
  end

  -- if parse_rules[context] then
  --   for k_out, rules in ipairs(parse_rules[context]) do
  --     print("k_out: ", k_out)
  --     for k, rule in ipairs(rules) do
  --       print("rule", k, rule)
  --       if parse_rules[rule] then
  --         print("truetrue")
  --         -- local new_context = parse_rules[v][1][1]
  --         -- print("new_context: ", new_context)
  --         -- return public.lua.parse_progress(tokens, parse_rules, new_context)
  --       else -- a token
  --         local token = tokens[1]
  --         print("token: ", token)
  --         print("v: ", rules)
  --       end
  --     end
  --     break
  --   end
  -- end

  local token = tokens[1]
  local tokens = P.rest(tokens)

  if token.label == 'list-open' then
    local parsed1, tokens1 =
      public.lua.parse_progress(tokens, parse_rules, context)
    local parsed2, tokens2 =
      public.lua.parse_progress(tokens1, parse_rules, context)
    return _.cons(parsed1, parsed2), tokens2
  elseif token.label == 'list-close' then
    return {}, tokens
  else
    local parsed, tokens =
      public.lua.parse_progress(tokens, parse_rules, context)
    return _.cons(token, parsed), tokens
  end
end

function public.lua.parse(sexp)
  local lex_rule = {
    {'whitespace', '%s+'},
    {'list-open', '%('},
    {'list-close', '%)'},
    {'vec-open', '%['},
    {'vec-close', '%]'},
    {'digit', '%d+'},
    {'string', '".-[^%\\]"'},
    {'keyword', ':[%-%+%*<>!=.:/%w]+'},
    {'identifier', "['%-%+%*<>!=.:/%w]+"}}
  local tokens = public.lua.tokenize(lex_rule, sexp)
  local parse_rules = {}
  parse_rules['expr'] = {
    {'list-open', 'many-expr', 'list-close'},
    -- {'vec-open', 'many-expr', 'vec-close'},
    {'whitespace'}, {'digit'}, {'string'},
    {'keyword'}, {'identifier'}}
  parse_rules['many-expr'] = {
    {'expr', 'many-expr'},
    {'expr'}}
  local ast, rest_tokens =
    public.lua.parse_progress(tokens, parse_rules, 'many-expr')
  if #rest_tokens == 0 then
    return ast
  else
    print("Failed to consume all tokens.")
  end
end

function public.vim.parse(sexp)
  local ast = public.lua.parse(sexp)
  return P.from_lua(ast)
end

_G[vital_context] = public
