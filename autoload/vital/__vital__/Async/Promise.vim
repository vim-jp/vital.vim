" ECMAScript like Promise library for asynchronous operations.
"   Spec: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise
" This implementation is based upon es6-promise npm package.
"   Repo: https://github.com/stefanpenner/es6-promise

" States of promise
let s:PENDING = 0
let s:FULFILLED = 1
let s:REJECTED = 2

let s:DICT_T = type({})
let s:NULL_T = type(v:null)

" @vimlint(EVL103, 1, a:resolve)
" @vimlint(EVL103, 1, a:reject)
function! s:noop(resolve, reject) abort
endfunction
" @vimlint(EVL103, 0, a:resolve)
" @vimlint(EVL103, 0, a:reject)
let s:NOOP = function('s:noop')

" Internal APIs

let s:PROMISE = {
    \   '_state': s:PENDING,
    \   '_children': [],
    \   '_fulfillments': [],
    \   '_rejections': [],
    \   '_result': v:null,
    \ }

let s:id = -1
function! s:_next_id() abort
  let s:id += 1
  return s:id
endfunction

" ... is added to use this function as a callback of timer_start()
function! s:_invoke_callback(settled, promise, callback, result, ...) abort
  let has_callback = type(a:callback) != s:NULL_T
  let success = 1
  if has_callback
    try
      let Result = a:callback(a:result)
    catch
      let Err = v:exception
      let success = 0
    endtry
  else
    let Result = a:result
  endif

  if a:promise._state != s:PENDING
    " Do nothing
  elseif has_callback && success
    call s:_resolve(a:promise, Result)
  elseif !success
    call s:_reject(a:promise, Err)
  elseif a:settled == s:FULFILLED
    call s:_fulfill(a:promise, Result)
  elseif a:settled == s:REJECTED
    call s:_reject(a:promise, Result)
  endif
endfunction

" ... is added to use this function as a callback of timer_start()
function! s:_publish(promise, ...) abort
  let settled = a:promise._state
  if empty(a:promise._children)
    return
  endif
  for i in range(len(a:promise._children))
    if settled == s:FULFILLED
      let l:CB = a:promise._fulfillments[i]
    elseif settled == s:REJECTED
      let l:CB = a:promise._rejections[i]
    else
      throw 'vital: Async.Promise: Cannot publish a pending promise'
    endif
    let child = a:promise._children[i]
    if type(child) != s:NULL_T
      call s:_invoke_callback(settled, child, l:CB, a:promise._result)
    else
      call l:CB(a:promise._result)
    endif
  endfor
  let a:promise._children = []
  let a:promise._fulfillments = []
  let a:promise._rejections = []
endfunction

function! s:_subscribe(parent, child, on_fulfilled, on_rejected) abort
  let is_empty = empty(a:parent._children)
  let a:parent._children += [ a:child ]
  let a:parent._fulfillments += [ a:on_fulfilled ]
  let a:parent._rejections += [ a:on_rejected ]
  if is_empty && a:parent._state > s:PENDING
    call timer_start(0, function('s:_publish', [a:parent]))
  endif
endfunction

function! s:_handle_thenable(promise, thenable) abort
  if a:thenable._state == s:FULFILLED
    call s:_fulfill(a:promise, a:thenable._result)
  elseif a:thenable._state == s:REJECTED
    call s:_reject(a:promise, a:thenable._result)
  else
    call s:_subscribe(
         \   a:thenable,
         \   v:null,
         \   function('s:_resolve', [a:promise]),
         \   function('s:_reject', [a:promise]),
         \ )
  endif
endfunction

function! s:_resolve(promise, ...) abort
  let Result = a:0 > 0 ? a:1 : v:null
  if s:is_promise(Result)
    call s:_handle_thenable(a:promise, Result)
  else
    call s:_fulfill(a:promise, Result)
  endif
endfunction

function! s:_fulfill(promise, value) abort
  if a:promise._state != s:PENDING
    return
  endif
  let a:promise._result = a:value
  let a:promise._state = s:FULFILLED
  if !empty(a:promise._children)
    call timer_start(0, function('s:_publish', [a:promise]))
  endif
endfunction

function! s:_reject(promise, ...) abort
  if a:promise._state != s:PENDING
    return
  endif
  let a:promise._result = a:0 > 0 ? a:1 : v:null
  let a:promise._state = s:REJECTED
  call timer_start(0, function('s:_publish', [a:promise]))
endfunction

function! s:_resolve_one(index, value) dict abort
  let self.done[a:index] = a:value
  let self.resolved += 1
  if self.resolved == self.total
    call self.resolve(self.done)
  endif
endfunction

function! s:_all(promises, resolve, reject) abort
  let total = len(a:promises)
  if total == 0
    call a:resolve([])
    return
  endif

  let wait_group = {
      \   'done': repeat([v:null], total),
      \   'resolve': a:resolve,
      \   'resolved': 0,
      \   'total': total,
      \   'notify_done': function('s:_resolve_one'),
      \ }

  " 'for' statement is not available here because iteration variable is captured into lambda
  " expression by **reference**.
  call map(
       \   copy(a:promises),
       \   {i, p -> p.then({v -> wait_group.notify_done(i, v)}, a:reject)},
       \ )
endfunction

function! s:_race(promises, resolve, reject) abort
  for p in a:promises
    call p.then(a:resolve, a:reject)
  endfor
endfunction

" Public APIs

function! s:new(resolver) abort
  let promise = deepcopy(s:PROMISE)
  let promise._vital_promise = s:_next_id()
  try
    if a:resolver != s:NOOP
      call a:resolver(
      \   function('s:_resolve', [promise]),
      \   function('s:_reject', [promise]),
      \ )
    endif
  catch
    call s:_reject(promise, v:exception)
  endtry
  return promise
endfunction

function! s:all(promises) abort
  return s:new(function('s:_all', [a:promises]))
endfunction

function! s:race(promises) abort
  return s:new(function('s:_race', [a:promises]))
endfunction

function! s:resolve(...) abort
  let promise = s:new(s:NOOP)
  call s:_resolve(promise, a:0 > 0 ? a:1 : v:null)
  return promise
endfunction

function! s:reject(...) abort
  let promise = s:new(s:NOOP)
  call s:_reject(promise, a:0 > 0 ? a:1 : v:null)
  return promise
endfunction

function! s:is_available() abort
  return has('nvim') || v:version >= 800
endfunction

function! s:is_promise(maybe_promise) abort
  return type(a:maybe_promise) == s:DICT_T && has_key(a:maybe_promise, '_vital_promise')
endfunction

function! s:_promise_then(...) dict abort
  let parent = self
  let state = parent._state
  let child = s:new(s:NOOP)
  let Res = get(a:000, 0, v:null)
  let Rej = get(a:000, 1, v:null)
  if state == s:FULFILLED
    call timer_start(0, function('s:_invoke_callback', [state, child, Res, parent._result]))
  elseif state == s:REJECTED
    call timer_start(0, function('s:_invoke_callback', [state, child, Rej, parent._result]))
  else
    call s:_subscribe(parent, child, Res, Rej)
  endif
  return child
endfunction
let s:PROMISE.then = function('s:_promise_then')

" .catch() is just a syntax sugar of .then()
function! s:_promise_catch(...) dict abort
  return self.then(v:null, get(a:000, 0, v:null))
endfunction
let s:PROMISE.catch = function('s:_promise_catch')

" vim:set et ts=2 sts=2 sw=2 tw=0:
