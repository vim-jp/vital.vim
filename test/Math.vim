scriptencoding utf-8

let s:suite = themis#suite('Math')
let s:assert = themis#helper('assert')

function! s:suite.before()
  let s:M = vital#of('vital').import('Math')
endfunction

function! s:suite.modulo()
  call s:assert.equals(s:M.modulo(10, 3), 1)
  call s:assert.equals(s:M.modulo(-10, 3), 2)
  call s:assert.equals(s:M.modulo(10, -3), -2)
  call s:assert.equals(s:M.modulo(-10, -3), -1)
endfunction

function! s:suite.fib()
  " It returns fib if it's less than or equal to 48
  call s:assert.equals(0, s:M.fib(0))
  call s:assert.equals(1, s:M.fib(1))
  call s:assert.equals(55, s:M.fib(10))
  call s:assert.equals(512559680, s:M.fib(48))
endfunction

function! s:suite.lcm()
  " It returns least common multiple number
  call s:assert.equals(s:M.lcm([2, 3]), 6 )
  call s:assert.equals(s:M.lcm([2, -3]), 6 )
  call s:assert.equals(s:M.lcm([7, 2, 3, 2]), 42)
  call s:assert.equals(s:M.lcm([0]), 0 )
  call s:assert.equals(s:M.lcm([2, 3, 0]), 0 )
endfunction

function! s:suite.gcd()
  " It returns greatest common divisor
  call s:assert.equals(s:M.gcd([2, 3]), 1 )
  call s:assert.equals(s:M.gcd([20, -30]), 10)
  call s:assert.equals(s:M.gcd([5, 20, 30]), 5 )
  call s:assert.equals(s:M.gcd([0]), 0 )
  call s:assert.equals(s:M.gcd([4, 0, 6]), 2 )
  call s:assert.equals(s:M.gcd([0, 0, 0]), 0 )
endfunction

function! s:suite.sum()
  " It returns sum integers
  call s:assert.equals(s:M.sum([1, 2, 3, 4, 5]), 15)

  " It returns sum real numbers
  call s:assert.equals(s:M.sum([1.0, 2.0, 3.2, 4.0, 5.3]), 15.5)
  call s:assert.equals(s:M.sum([1, 2, 3.2, 4, 5.3]), 15.5)

  " It throws illigal arguments
  try
    call s:M.sum([1, 2, '3', 4, 5])
    call s:assert.fail('Not thrown illegal arguments')
  catch
  endtry

  " It returns argument is empty list
  call s:assert.equals(s:M.sum([]), 0)
endfunction

function! s:suite.round()
  call s:assert.equals(s:M.round(2.675, 0), 3)
  call s:assert.equals(s:M.round(2.675, 2), 2.68)
  call s:assert.equals(s:M.round(-2.675, 2), -2.68)
  call s:assert.equals(s:M.round(5.127, -1), 10.0)
  call s:assert.equals(s:M.round(5.127, 0), 5.0)
  call s:assert.equals(s:M.round(5.127, 1), 5.1)
  call s:assert.equals(s:M.round(5.127, 2), 5.13)
  call s:assert.equals(s:M.round(5.127, 3), 5.127)
  call s:assert.equals(s:M.round(5.127, 20), 5.127)
  call s:assert.equals(s:M.round(123, -2), 100.0)
  call s:assert.equals(s:M.round(123, -1), 120.0)
  call s:assert.equals(s:M.round(123, 1), 123.0)
endfunction
