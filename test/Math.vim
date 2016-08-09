scriptencoding utf-8

let s:suite = themis#suite('Math')
let s:assert = themis#helper('assert')

function! s:suite.before()
  let s:M = vital#vital#new().import('Math')
endfunction

function! s:suite.modulo()
  call s:assert.equals(s:M.modulo(10, 3), 1)
  call s:assert.equals(s:M.modulo(-10, 3), 2)
  call s:assert.equals(s:M.modulo(10, -3), -2)
  call s:assert.equals(s:M.modulo(-10, -3), -1)
endfunction

function! s:suite.fib()
  " It returns fib if it's less than or equal to 48
  call s:assert.equals(s:M.fib(0), 0)
  call s:assert.equals(s:M.fib(1), 1)
  call s:assert.equals(s:M.fib(10), 55)
  call s:assert.equals(s:M.fib(47), 2971215073)
  if has('num64')
    call s:assert.equals(s:M.fib(48), 4807526976)
  else
    call s:assert.equals(s:M.fib(48), 512559680)
  endif
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

function! s:suite.sum_integeres()
  " It returns sum integers
  call s:assert.equals(s:M.sum([1, 2, 3, 4, 5]), 15)
endfunction

function! s:suite.sum_real_numbers()
  " It returns sum real numbers
  call s:assert.equals(s:M.sum([1.0, 2.0, 3.2, 4.0, 5.3]), 15.5)
  call s:assert.equals(s:M.sum([1, 2, 3.2, 4, 5.3]), 15.5)
endfunction

function! s:suite.sum_throws_illegal_arguments()
  " It throws illigal arguments
  Throws s:M.sum([1, 2, '3', 4, 5])
endfunction

function! s:suite.sum_unit_when_empty()
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

function! s:suite.str2nr()
  call s:assert.is_number(s:M.str2nr('0'))
  call s:assert.is_number(s:M.str2nr('123'))
  call s:assert.is_number(s:M.str2nr('ABCD', 16))
  call s:assert.equals(s:M.str2nr('345'), 345)
  call s:assert.equals(s:M.str2nr('0', 10), 0)
  call s:assert.equals(s:M.str2nr('1', 10), 1)
  call s:assert.equals(s:M.str2nr('10', 10), 10)
  call s:assert.equals(s:M.str2nr('-1', 10), -1)
  call s:assert.equals(s:M.str2nr('-10', 10), -10)
  call s:assert.equals(s:M.str2nr('0', 2), 0)
  call s:assert.equals(s:M.str2nr('10', 2), 2)
  call s:assert.equals(s:M.str2nr('ZZ', 36), 1295)
  call s:assert.equals(s:M.str2nr('ABCD', 14), 29777)
  call s:assert.equals(s:M.str2nr('WXYZ', 36), 1537019)
  call s:assert.equals(s:M.str2nr('wxyz', 36), 1537019)
  call s:assert.equals(s:M.str2nr('WxYz', 36), 1537019)
  call s:assert.equals(s:M.str2nr('030', 10), 30)
  let Math = s:M
  Throws /^vital: Math: given string/ Math.str2nr('2', 2)
  Throws /^vital: Math: given string/ Math.str2nr('ZZ', 10)
  Throws /^vital: Math: base number/ Math.str2nr('0', 1)
  Throws /^vital: Math: base number/ Math.str2nr('0', 37)
endfunction

function! s:suite.nr2str()
  call s:assert.equals(s:M.nr2str(345), '345')
  call s:assert.equals(s:M.nr2str(0, 10), '0')
  call s:assert.equals(s:M.nr2str(1, 10), '1')
  call s:assert.equals(s:M.nr2str(10, 10), '10')
  call s:assert.equals(s:M.nr2str(-1, 10), '-1')
  call s:assert.equals(s:M.nr2str(-10,10), '-10')
  call s:assert.equals(s:M.nr2str(0, 2), '0')
  call s:assert.equals(s:M.nr2str(2, 2), '10')
  call s:assert.equals(s:M.nr2str(1295, 36), 'ZZ')
  call s:assert.equals(s:M.nr2str(29777, 14), 'ABCD')
  call s:assert.equals(s:M.nr2str(1537019, 36), 'WXYZ')
  let Math = s:M
  Throws /^vital: Math: base number/ Math.nr2str(1, 1)
  Throws /^vital: Math: base number/ Math.nr2str(1, 37)
endfunction

