" Text.Sexp
" Author: Tatsuhiro Ujihisa

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V)
  let s:V = a:V
  let s:P = s:V.import('Experimental.Lua.Prelude')
  let s:LuaP = s:P.lua_namespace()

lua << EOF
local _ = {}

local P = _G[vim.eval('s:LuaP')].lua

function _.rest(array, index)
  index = index or 2
  local rest = {}
  for i = index, #array do
    rest[#rest + 1] = array[i]
  end
  return rest
end

function _.cons(x, xs)
  local memo = {x}
  for _, v in ipairs(xs) do
    table.insert(memo, v)
  end
  return memo
end

vital_text_sexp = {}

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

local lualist2vimlist = function(lualist)
  local memo = vim.list()
  for _, v in ipairs(lualist) do
    memo:add(P.from_lua(v))
  end
  return memo
end

local luadict2vimdict = function(luadict)
  local memo = vim.dict()
  for k, v in pairs(luadict) do
    memo[k] = P.from_lua(v)
  end
  return memo
end

local is_list = function(tbl)
  -- http://stackoverflow.com/questions/6077006/how-can-i-check-if-a-lua-table-contains-only-sequential-numeric-indices
  local numKeys = 0
  for _, _ in pairs(tbl) do
    numKeys = numKeys+1
  end
  local numIndices = 0
  for _, _ in ipairs(tbl) do
    numIndices = numIndices+1
  end
  return numKeys == numIndices
end

-- local size_iterator = function(iter)
--   local i = 0
--   for _ in iter do
--     i = i + 1
--   end
--   return i
-- end

function vital_text_sexp.tokenize(sexp)
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

function vital_text_sexp.parse_progress(tokens, parse_rules, context)
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
  --         -- return vital_text_sexp.parse_progress(tokens, parse_rules, new_context)
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
  local tokens = _.rest(tokens)

  if token.label == 'list-open' then
    local parsed1, tokens1 =
      vital_text_sexp.parse_progress(tokens, parse_rules, context)
    local parsed2, tokens2 =
      vital_text_sexp.parse_progress(tokens1, parse_rules, context)
    return _.cons(parsed1, parsed2), tokens2
  elseif token.label == 'list-close' then
    return {}, tokens
  else
    local parsed, tokens =
      vital_text_sexp.parse_progress(tokens, parse_rules, context)
    return _.cons(token, parsed), tokens
  end
end

function vital_text_sexp.parse(sexp)
  local tokens = vital_text_sexp.tokenize(sexp)
  -- return lualist2vimlist(P.map(tokens, luadict2vimdict))
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
    vital_text_sexp.parse_progress(tokens, parse_rules, 'many-expr')
  if #rest_tokens == 0 then
    return P.from_lua(ast)
  else
    print("Failed to consume all tokens.")
  end
end

-- function vital_text_sexp.parse(tokens)
--   local memo = {}
--   for _, token in pairs(tokens) do
--     memo:add(token['label'])
--   end
--   return memo
-- end
EOF

endfunction

function! s:_vital_depends()
  return ['Experimental.Lua.Prelude']
endfunction

function! s:parse(sexp)
  if has('lua')
    return luaeval('vital_text_sexp.parse(_A)', a:sexp)
    " return luaeval('vital_text_sexp.parse(vital_text_sexp.parse(_A))', a:sexp)
  else
    throw 'Vital.Text.Sexp: any function call needs if_lua'
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim:set et ts=2 sts=2 sw=2 tw=0:
