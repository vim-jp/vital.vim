let s:suite = themis#suite('Data.BigNum')
let s:assert = themis#helper('assert')

function! s:suite.before()
  let s:BigNum = vital#of('vital').import('Data.BigNum')
endfunction

function! s:suite.after()
  unlet! s:BigNum
endfunction

function! s:suite.from_int() abort
  call s:assert.equals(s:BigNum.from_int(0), {'num': [0], 'sign': 1})
  call s:assert.equals(s:BigNum.from_int(123), {'num': [123], 'sign': 1})
  call s:assert.equals(s:BigNum.from_int(-789), {'num': [789], 'sign': -1})
  call s:assert.equals(s:BigNum.from_int(2147483647), {'num': [21, 4748, 3647], 'sign': 1})
  call s:assert.equals(s:BigNum.from_int(-2147483648), {'num': [21, 4748, 3648], 'sign': -1})
endfunction

function! s:suite.from_string() abort
  call s:assert.equals(s:BigNum.from_string("0"), {'num': [0], 'sign': 1})
  call s:assert.equals(s:BigNum.from_string("123"), {'num': [123], 'sign': 1})
  call s:assert.equals(s:BigNum.from_string("12345678901"), {'num': [123, 4567, 8901], 'sign': 1})
  call s:assert.equals(s:BigNum.from_string("-123"), {'num': [123], 'sign': -1})
  call s:assert.equals(s:BigNum.from_string("-12345678901"), {'num': [123, 4567, 8901], 'sign': -1})
  call s:assert.equals(s:BigNum.from_string("10002000300040000"), {'num': [1, 2, 3, 4, 0], 'sign': 1})
endfunction

function! s:suite.to_string() abort
  call s:assert.equals(s:BigNum.to_string({'num': [0], 'sign': 1}), "0")
  call s:assert.equals(s:BigNum.to_string({'num': [123], 'sign': 1}), "123")
  call s:assert.equals(s:BigNum.to_string({'num': [123, 4567, 8901], 'sign': 1}), "12345678901")
  call s:assert.equals(s:BigNum.to_string({'num': [123], 'sign': -1}), "-123")
  call s:assert.equals(s:BigNum.to_string({'num': [123, 4567, 8901], 'sign': -1}), "-12345678901")
  call s:assert.equals(s:BigNum.to_string({'num': [1, 2, 3, 4, 0], 'sign': 1}), "10002000300040000")
endfunction

function! s:suite.compare() abort
  call s:assert.equals(s:BigNum.compare(0, 0), 0)
  call s:assert.equals(s:BigNum.compare(1, 1), 0)
  call s:assert.equals(s:BigNum.compare(-1, -1), 0)
  call s:assert.equals(s:BigNum.compare(2, 1), 1)
  call s:assert.equals(s:BigNum.compare(1, 2), -1)
  call s:assert.equals(s:BigNum.compare(1, -1), 1)
  call s:assert.equals(s:BigNum.compare(-1, 1), -1)
  call s:assert.equals(s:BigNum.compare("12345678901", 0), 1)
  call s:assert.equals(s:BigNum.compare("-12345678901", 0), -1)
  call s:assert.equals(s:BigNum.compare("12345678901", "12345678901"), 0)
  call s:assert.equals(s:BigNum.compare("-12345678901", "-12345678901"), 0)
  call s:assert.equals(s:BigNum.compare("12345678901", "11111111111"), 1)
  call s:assert.equals(s:BigNum.compare("-123456789123456789", "-11111111111"), -1)
endfunction

function! s:suite.add() abort
  " int32 + int32
  call s:assert.equals(s:BigNum.add(0, 0), s:BigNum.from_int(0))
  call s:assert.equals(s:BigNum.add(-1, 999), s:BigNum.from_int(998))
  call s:assert.equals(s:BigNum.add(-1000, -1234), s:BigNum.from_int(-2234))
  " bigint + int32
  call s:assert.equals(s:BigNum.add("9999999999999999", 1), s:BigNum.from_string("10000000000000000"))
  call s:assert.equals(s:BigNum.add("9999999999999999", -1), s:BigNum.from_string("9999999999999998"))
  call s:assert.equals(s:BigNum.add("-12345678901", 111111111), s:BigNum.from_string("-12234567790"))
  call s:assert.equals(s:BigNum.add("-12345678901", -111111111), s:BigNum.from_string("-12456790012"))
  " bigint + bigint
  call s:assert.equals(s:BigNum.add("9999999999999999", "1111111111111111"), s:BigNum.from_string("11111111111111110"))
  call s:assert.equals(s:BigNum.add("9999999999999999", "-1111111111111111"), s:BigNum.from_string("8888888888888888"))
  call s:assert.equals(s:BigNum.add("-12345123451234512345", "10000100001000010000"), s:BigNum.from_string("-2345023450234502345"))
  call s:assert.equals(s:BigNum.add("-12345123451234512345", "-50000500005000050000"), s:BigNum.from_string("-62345623456234562345"))
endfunction

function! s:suite.sub() abort
  " int32 - int32
  call s:assert.equals(s:BigNum.sub(0, 0), s:BigNum.from_int(0))
  call s:assert.equals(s:BigNum.sub(-1, 999), s:BigNum.from_int(-1000))
  call s:assert.equals(s:BigNum.sub(-1000, -1234), s:BigNum.from_int(234))
  " bigint - int32
  call s:assert.equals(s:BigNum.sub("9999999999999999", 1), s:BigNum.from_string("9999999999999998"))
  call s:assert.equals(s:BigNum.sub("9999999999999999", -1), s:BigNum.from_string("10000000000000000"))
  call s:assert.equals(s:BigNum.sub("-12345678901", 111111111), s:BigNum.from_string("-12456790012"))
  call s:assert.equals(s:BigNum.sub("-12345678901", -111111111), s:BigNum.from_string("-12234567790"))
  " bigint + bigint
  call s:assert.equals(s:BigNum.sub("9999999999999999", "1111111111111111"), s:BigNum.from_string("8888888888888888"))
  call s:assert.equals(s:BigNum.sub("9999999999999999", "-1111111111111111"), s:BigNum.from_string("11111111111111110"))
  call s:assert.equals(s:BigNum.sub("-12345123451234512345", "10000100001000010000"), s:BigNum.from_string("-22345223452234522345"))
  call s:assert.equals(s:BigNum.sub("-12345123451234512345", "-50000500005000050000"), s:BigNum.from_string("37655376553765537655"))
endfunction

function! s:suite.mul() abort
  " int32 * int32 -> int32
  call s:assert.equals(s:BigNum.mul(0, 0), s:BigNum.from_int(0))
  call s:assert.equals(s:BigNum.mul(12345678, 9), s:BigNum.from_int(111111102))
  call s:assert.equals(s:BigNum.mul(-12345678, 2), s:BigNum.from_int(-24691356))
  call s:assert.equals(s:BigNum.mul(-3, -2), s:BigNum.from_int(6))
  " int32 * int32 -> bigint
  call s:assert.equals(s:BigNum.mul(1234567890, 1234567890), s:BigNum.from_string("1524157875019052100"))
  call s:assert.equals(s:BigNum.mul(-2147483648, -2147483648), s:BigNum.from_string("4611686018427387904"))
  " bigint * int32
  call s:assert.equals(s:BigNum.mul("1234567890123", 0), s:BigNum.from_int(0))
  call s:assert.equals(s:BigNum.mul("1234567890123", 2), s:BigNum.from_string("2469135780246"))
  call s:assert.equals(s:BigNum.mul("1234567890123", -2), s:BigNum.from_string("-2469135780246"))
  call s:assert.equals(s:BigNum.mul("-1234567890123", 2), s:BigNum.from_string("-2469135780246"))
  call s:assert.equals(s:BigNum.mul("-1234567890123", -2), s:BigNum.from_string("2469135780246"))
  " bigint * bigint
  call s:assert.equals(s:BigNum.mul("1234567890123", "1234567890123"), s:BigNum.from_string("1524157875322755800955129"))
  call s:assert.equals(s:BigNum.mul("-111111111111", "-111111111111"), s:BigNum.from_string("12345679012320987654321"))
endfunction

function! s:suite.div() abort
  " int32 / int32
  call s:assert.equals(s:BigNum.div(123456780, 12345678), s:BigNum.from_int(10))
  call s:assert.equals(s:BigNum.div(123, -123), s:BigNum.from_int(-1))
  call s:assert.equals(s:BigNum.div(-123, 123), s:BigNum.from_int(-1))
  call s:assert.equals(s:BigNum.div(-123, -123), s:BigNum.from_int(1))
  " bigint / int32 -> int32
  call s:assert.equals(s:BigNum.div("10000001000000", 1000000), s:BigNum.from_int(10000001))
  call s:assert.equals(s:BigNum.div("-10000001000000", 1000000), s:BigNum.from_int(-10000001))
  call s:assert.equals(s:BigNum.div("-10000001000000", -1000000), s:BigNum.from_int(10000001))
  " bigint / int32 -> bigintNum
  call s:assert.equals(s:BigNum.div("123123123123123", 123), s:BigNum.from_string("1001001001001"))
  call s:assert.equals(s:BigNum.div("-123123123123123", 123), s:BigNum.from_string("-1001001001001"))
  call s:assert.equals(s:BigNum.div("123123123123123", -123), s:BigNum.from_string("-1001001001001"))
  " bigint / bigint -> int32Num
  call s:assert.equals(s:BigNum.div("1112345678999", "1112345679990"), s:BigNum.from_int(0))
  call s:assert.equals(s:BigNum.div("12345678901234567890", "1234567890123456789"), s:BigNum.from_int(10))
  call s:assert.equals(s:BigNum.div("-12345678901234567890", "1234567890123456789"), s:BigNum.from_int(-10))
  call s:assert.equals(s:BigNum.div("-12345678901234567890", "-1234567890123456789"), s:BigNum.from_int(10))
  " bigint / bigint -> biginNum
  call s:assert.equals(s:BigNum.div("519920419074760465703", "22801763489"), s:BigNum.from_string("22801763527"))
  call s:assert.equals(s:BigNum.div("-1522605027922533360535618378132637429718068114961380688657908494580122963258952897654000350692006139", "37975227936943673922808872755445627854565536638199"), s:BigNum.from_string("-40094690950920881030683735292761468389214899724061"))
endfunction

function! s:suite.mod() abort
  call s:assert.equals(s:BigNum.mod(3, -2), s:BigNum.from_int(1))
  call s:assert.equals(s:BigNum.mod(-3, 2), s:BigNum.from_int(-1))
  call s:assert.equals(s:BigNum.mod(-3, -2), s:BigNum.from_int(-1))
  call s:assert.equals(s:BigNum.mod(123456780, 12345678), s:BigNum.from_int(0))
  call s:assert.equals(s:BigNum.mod(123, 123), s:BigNum.from_int(0))
  call s:assert.equals(s:BigNum.mod("123456789", "123456790"), s:BigNum.from_int(123456789))
  call s:assert.equals(s:BigNum.mod("-1234567890123456789", "-1234567890123456790"), s:BigNum.from_string("-1234567890123456789"))
  call s:assert.equals(s:BigNum.mod("519920419074760465703", "-22801763489"), s:BigNum.from_int(0))
endfunction

function! s:suite.div_mod() abort
  call s:assert.equals(s:BigNum.div_mod("519920419074760465703", "22801763489"), [s:BigNum.from_string("22801763527"), s:BigNum.from_int(0)])
endfunction

function! s:suite.sign() abort
  call s:assert.equals(s:BigNum.sign(0), 0)
  call s:assert.equals(s:BigNum.sign(3), 1)
  call s:assert.equals(s:BigNum.sign(-3), -1)
  call s:assert.equals(s:BigNum.sign("1234567890123"), 1)
  call s:assert.equals(s:BigNum.sign("-1234567890123"), -1)
endfunction

function! s:suite.neg() abort
  call s:assert.equals(s:BigNum.neg(0), s:BigNum.from_int(0))
  call s:assert.equals(s:BigNum.neg(-1111), s:BigNum.from_int(1111))
  call s:assert.equals(s:BigNum.neg("1234567890123"), s:BigNum.from_string("-1234567890123"))
endfunction

