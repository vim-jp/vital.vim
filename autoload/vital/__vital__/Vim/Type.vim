let s:types = {
\   'number': 0,
\   'string': 1,
\   'func': 2,
\   'list': 3,
\   'dict': 4,
\   'float': 5,
\   'bool': 6,
\   'none': 7,
\   'job': 8,
\   'channel': 9,
\ }
lockvar 1 s:types

let s:type_names = {
\   '0': 'number',
\   '1': 'string',
\   '2': 'func',
\   '3': 'list',
\   '4': 'dict',
\   '5': 'float',
\   '6': 'bool',
\   '7': 'none',
\   '8': 'job',
\   '9': 'channel',
\ }
lockvar 1 s:type_names

function! s:_vital_created(module) abort
  let a:module.types = s:types
  let a:module.type_names = s:type_names
endfunction


function! s:is_number(value) abort
  return type(a:value) == s:types.number
endfunction

function! s:is_string(value) abort
  return type(a:value) == s:types.string
endfunction

function! s:is_func(value) abort
  return type(a:value) == s:types.func
endfunction

function! s:is_list(value) abort
  return type(a:value) == s:types.list
endfunction

function! s:is_dict(value) abort
  return type(a:value) == s:types.dict
endfunction

function! s:is_float(value) abort
  return type(a:value) == s:types.float
endfunction

function! s:is_bool(value) abort
  return type(a:value) == s:types.bool
endfunction

function! s:is_none(value) abort
  return type(a:value) == s:types.none
endfunction

function! s:is_job(value) abort
  return type(a:value) == s:types.job
endfunction

function! s:is_channel(value) abort
  return type(a:value) == s:types.channel
endfunction

function! s:is_numeric(value) abort
  let t = type(a:value)
  return t == s:types.number || t == s:types.float
endfunction

function! s:is_special(value) abort
  let t = type(a:value)
  return t == s:types.bool || t == s:types.none
endfunction

function! s:is_predicate(value) abort
  let t = type(a:value)
  return t == s:types.number || t == s:types.string ||
  \ t == s:types.bool || t == s:types.none
endfunction
