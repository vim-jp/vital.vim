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
      \ '_state': s:PENDING,
      \ '_children': [],
      \ '_fulfillments': [],
      \ '_rejections': [],
      \ '_result': v:null,
      \ }

let s:id = -1
function! s:_next_id() abort
  let s:id += 1
  return s:id
endfunction

function! s:_invoke_callback(settled, promise, callback, result) abort
  let has_callback = type(a:callback) != s:NULL_T
  let success = 1
  if has_callback
    try
      let value = a:callback(a:result)
    catch
      let err = v:exception
      let success = 0
    endtry
  else
    let value = a:result
  endif

  if a:promise._state != s:PENDING
    " Do nothing
  elseif has_callback && success
    call s:_resolve(a:promise, value)
  elseif !success
    call s:_reject(a:promise, err)
  elseif a:settled == s:FULFILLED
    call s:_fulfill(a:promise, value)
  elseif a:settled == s:REJECTED
    call s:_reject(a:promise, value)
  endif
endfunction

function! s:_publish(promise) abort
  let settled = a:promise._state
  if empty(a:promise._children)
    return
  endif
  for i in range(len(a:promise._children))
    if settled == s:FULFILLED
      let CB = a:promise._fulfillments[i]
    elseif settled == s:REJECTED
      let CB = a:promise._rejections[i]
    else
      throw 'vital: Async.Promise: Cannot publish a pending promise'
    endif
    let child = a:promise._children[i]
    if type(child) != s:NULL_T
      call s:_invoke_callback(settled, child, CB, a:promise._result)
    else
      call CB(a:promise._result)
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
    " In ECMAScript spec, this callback must be called asynchronously, but Vim script does not have
    " asynchronous function such as setTimeout(). So call the callback synchronously here.
    call s:_publish(a:parent)
  endif
endfunction

function! s:_handle_thenable(promise, thenable) abort
  if a:thenable._state == s:FULFILLED
    call s:_fulfill(a:promise, a:thenable._result)
  elseif a:thenable._state == s:REJECTED
    call s:_reject(a:promise, a:thenable._result)
  else
    call s:_subscribe(
          \ a:thenable,
          \ v:null,
          \ {result -> s:_resolve(a:promise, result)},
          \ {reason -> s:_reject(a:promise, reason)},
        \ )
  endif
endfunction

function! s:_resolve(promise, value) abort
  if s:is_promise(a:value)
    call s:_handle_thenable(a:promise, a:value)
  else
    call s:_fulfill(a:promise, a:value)
  endif
endfunction

function! s:_fulfill(promise, value) abort
  if a:promise._state != s:PENDING
    return
  endif
  let a:promise._result = a:value
  let a:promise._state = s:FULFILLED
  if !empty(a:promise._children)
    " In ECMAScript spec, this callback must be called asynchronously but Vim script does not have
    " asynchronous function such as setTimeout(). So call the callback synchronously here.
    call s:_publish(a:promise)
  endif
endfunction

function! s:_reject(promise, reason) abort
  if a:promise._state != s:PENDING
    return
  endif
  let a:promise._result = a:reason
  let a:promise._state = s:REJECTED
  " In ECMAScript spec, this callback must be called asynchronously, but Vim script does not have
  " asynchronous function such as setTimeout(). So call the callback synchronously here.
  call s:_publish(a:promise)
endfunction

function! s:_all(resolve, reject, promises) abort
  let total = len(a:promises)
  let fulfiller = {
        \ 'done': repeat([v:null], total),
        \ 'resolve': a:resolve,
        \ 'resolved': 0,
        \ 'total': total,
        \ }

  function! fulfiller.fullfill(index, value) abort dict
    let self.done[a:index] = a:value
    let self.resolved += 1
    if self.resolved == self.total
      call self.resolve(self.done)
    endif
  endfunction

  " 'for' statement is not available here because iteration variable is captured into lambda
  " expression by **reference**.
  call map(
        \ copy(a:promises),
        \ {i, p -> p.then({V -> fulfiller.fullfill(i, V)}, a:reject)},
      \ )
endfunction

function! s:_race(resolve, reject, promises) abort
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
        \ {Value -> s:_resolve(promise, Value)},
        \ {Reason -> s:_reject(promise, Reason)},
      \ )
    endif
  catch
    call s:_reject(promise, v:exception)
  endtry
  return promise
endfunction

function! s:all(promises) abort
  return s:new({resolve, reject -> s:_all(resolve, reject, a:promises)})
endfunction

function! s:race(promises) abort
  return s:new({resolve, reject -> s:_race(resolve, reject, a:promises)})
endfunction

function! s:resolve(value) abort
  let promise = s:new(s:NOOP)
  call s:_resolve(promise, a:value)
  return promise
endfunction

function! s:reject(reason) abort
  let promise = s:new(s:NOOP)
  call s:_reject(promise, a:reason)
  return promise
endfunction

function! s:is_available() abort
  return has('nvim') || v:version >= 800
endfunction

function! s:is_promise(maybe_promise) abort
  return type(a:maybe_promise) == s:DICT_T && has_key(a:maybe_promise, '_vital_promise')
endfunction

function! s:PROMISE.then(...) abort dict
  let parent = self
  let state = parent._state
  let child = s:new(s:NOOP)
  if state == s:FULFILLED
    " In ECMAScript spec, this callback must be called asynchronously, but Vim script does not have
    " asynchronous function such as setTimeout(). So call the callback synchronously here.
    call s:_invoke_callback(state, child, get(a:000, 0, v:null), parent._result)
  elseif state == s:REJECTED
    " In ECMAScript spec, this callback must be called asynchronously, but Vim script does not have
    " asynchronous function such as setTimeout(). So call the callback synchronously here.
    call s:_invoke_callback(state, child, get(a:000, 1, v:null), parent._result)
  else
    call s:_subscribe(parent, child, get(a:000, 0, v:null), get(a:000, 1, v:null))
  endif
  return child
endfunction

" .catch() is just a syntax sugar of .then()
function! s:PROMISE.catch(on_rejected) abort
  return self.then(v:null, a:on_rejected)
endfunction

" vim:set et ts=2 sts=2 sw=2 tw=0:
