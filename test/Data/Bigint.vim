let s:suite = themis#suite('Data.Bigint')
let s:assert = themis#helper('assert')

function! s:suite.before()
  let s:Bigint = vital#of('vital').import('Data.Bigint')
endfunction

function! s:suite.after()
  unlet! s:Bigint
endfunction

function! s:suite.from_int() abort
  call s:assert.equals(s:Bigint.from_int(0), {'num': [0], 'sign': 1})
  call s:assert.equals(s:Bigint.from_int(123), {'num': [123], 'sign': 1})
  call s:assert.equals(s:Bigint.from_int(-789), {'num': [789], 'sign': -1})
endfunction

function! s:suite.from_string() abort
  call s:assert.equals(s:Bigint.from_string("0"), {'num': [0], 'sign': 1})
  call s:assert.equals(s:Bigint.from_string("123"), {'num': [123], 'sign': 1})
  call s:assert.equals(s:Bigint.from_string("1234567890"), {'num': [12, 3456, 7890], 'sign': 1})
endfunction

function! s:suite.to_string() abort
  call s:assert.equals(s:Bigint.to_string({'num': [0], 'sign': 1}), "0")
  call s:assert.equals(s:Bigint.to_string({'num': [123], 'sign': 1}), "123")
  call s:assert.equals(s:Bigint.to_string({'num': [12, 3456, 7890], 'sign': 1}), "1234567890")
endfunction

function! s:suite.compare() abort
  call s:assert.equals(s:Bigint.compare(0, 0), 0)
  call s:assert.equals(s:Bigint.compare(1, 1), 0)
  call s:assert.equals(s:Bigint.compare(-1, -1), 0)
  call s:assert.equals(s:Bigint.compare(2, 1), 1)
  call s:assert.equals(s:Bigint.compare(1, 2), -1)
  call s:assert.equals(s:Bigint.compare(1, -1), 1)
  call s:assert.equals(s:Bigint.compare(-1, 1), -1)
  call s:assert.equals(s:Bigint.compare("1234567890", 0), 1)
  call s:assert.equals(s:Bigint.compare("-1234567890", 0), -1)
  call s:assert.equals(s:Bigint.compare("1234567890", "1234567890"), 0)
endfunction

function! s:suite.add() abort
  call s:assert.equals(s:Bigint.add(0, 0), s:Bigint.from_int(0))
  call s:assert.equals(s:Bigint.add("9999999999999999", 1), s:Bigint.from_string("10000000000000000"))
  call s:assert.equals(s:Bigint.add(-1, 999), s:Bigint.from_int(998))
  call s:assert.equals(s:Bigint.add(-1000, -1234), s:Bigint.from_int(-2234))
  call s:assert.equals(s:Bigint.add("-123456789", 111111111), s:Bigint.from_int(-12345678))
endfunction

function! s:suite.sub() abort
  call s:assert.equals(s:Bigint.sub(0, 0), s:Bigint.from_int(0))
  call s:assert.equals(s:Bigint.sub(99999999, -1), s:Bigint.from_int(100000000))
  call s:assert.equals(s:Bigint.sub(-1, -999), s:Bigint.from_int(998))
  call s:assert.equals(s:Bigint.sub(-1000, 1234), s:Bigint.from_int(-2234))
  call s:assert.equals(s:Bigint.sub(-123456789, -111111111), s:Bigint.from_int(-12345678))
  call s:assert.equals(s:Bigint.sub("1122334455667788", "1111111111111111"), s:Bigint.from_string("11223344556677"))
endfunction

function! s:suite.mul() abort
  call s:assert.equals(s:Bigint.mul(0, 0), s:Bigint.from_int(0))
  call s:assert.equals(s:Bigint.mul(1234567890, 1234567890), s:Bigint.from_string("1524157875019052100"))
  call s:assert.equals(s:Bigint.mul(12345678, 9), s:Bigint.from_int(111111102))
  call s:assert.equals(s:Bigint.mul("1234567890123", 0), s:Bigint.from_int(0))
endfunction

function! s:suite.div() abort
  call s:assert.equals(s:Bigint.div(123456780, 12345678), s:Bigint.from_int(10))
  call s:assert.equals(s:Bigint.div(123, 123), s:Bigint.from_int(1))
  call s:assert.equals(s:Bigint.div("11123456789", "11123456790"), s:Bigint.from_int(0))
  call s:assert.equals(s:Bigint.div("519920419074760465703", "22801763489"), s:Bigint.from_string("22801763527"))
endfunction

function! s:suite.mod() abort
  call s:assert.equals(s:Bigint.mod(3, -2), s:Bigint.from_int(1))
  call s:assert.equals(s:Bigint.mod(-3, 2), s:Bigint.from_int(-1))
  call s:assert.equals(s:Bigint.mod(-3, -2), s:Bigint.from_int(-1))
  call s:assert.equals(s:Bigint.mod(123456780, 12345678), s:Bigint.from_int(0))
  call s:assert.equals(s:Bigint.mod(123, 123), s:Bigint.from_int(0))
  call s:assert.equals(s:Bigint.mod("123456789", "123456790"), s:Bigint.from_int(123456789))
  call s:assert.equals(s:Bigint.mod("519920419074760465703", "22801763489"), s:Bigint.from_int(0))
endfunction

function! s:suite.div_mod() abort
  call s:assert.equals(s:Bigint.div_mod("519920419074760465703", "22801763489"), [s:Bigint.from_string("22801763527"), s:Bigint.from_int(0)])
endfunction

function! s:suite.sign() abort
  call s:assert.equals(s:Bigint.sign("1234567890123"), 1)
  call s:assert.equals(s:Bigint.sign(0), 0)
  call s:assert.equals(s:Bigint.sign(-3), -1)
endfunction

function! s:suite.neg() abort
  call s:assert.equals(s:Bigint.neg(-1111), s:Bigint.from_int(1111))
endfunction

