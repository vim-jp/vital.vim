" math utilities.

let s:save_cpo = &cpo
set cpo&vim

" TODO Simpler way?
function! s:modulo(m, n)
  let d = a:m * a:n < 0 ? 1 : 0
  return a:m + (-(a:m + (0 < a:n ? d : -d)) / a:n + d) * a:n
endfunction

function! s:fib(n)
  let [a, b, i] = [0, 1, 0]
  while i < a:n
    let [a, b, i] = [b, a + b, i + 1]
  endwhile
  return a
endfunction

function! s:_lcm(m, n)
  if a:m == 0 || a:n == 0
    return 0
  endif
  return (a:m / s:_gcd(a:m, a:n)) * a:n
endfunction

function! s:_gcd(m, n)
  if a:m == 0 && a:n == 0
    return 0
  elseif a:m == 0
    return a:n
  elseif a:n == 0
    return a:m
  endif
  let tmp = 0
  let m = a:m
  let n = a:n
  while m % n != 0
    let tmp = n
    let n = m % n
    let m = tmp
  endwhile
  return n
endfunction

function! s:lcm(list)
  let list = map(a:list, 'abs(v:val)')
  if len(list) == 0
    throw 'vital: Math: Empty list'
  endif
  while len(list) > 1
    let list = [s:_lcm(list[0], list[1])] + list[2:]
  endwhile
  return list[0]
endfunction

function! s:gcd(list)
  let list = map(a:list, 'abs(v:val)')
  if len(list) == 0
    throw 'vital: Math: Empty list'
  endif
  while len(list) > 1
    let list = [s:_gcd(list[0], list[1])] + list[2:]
  endwhile
  return list[0]
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
