scriptencoding utf-8

let s:suite = themis#suite('Validator.Args')
let s:assert = themis#helper('assert')

function! s:assert_null_support() abort
  if !exists('v:null')
    Skip "this version of vim/neovim does not support v:null"
  endif
endfunction

function! s:assert_job_support() abort
  if !exists('*test_null_job')
    Skip "this version of vim does not support job"
  endif
endfunction

function! s:assert_channel_support() abort
  if !exists('*test_null_channel')
    Skip "this version of vim does not support channel"
  endif
endfunction

function! s:assert_blob_support() abort
  if !exists('*test_null_blob')
    Skip "this version of vim does not support blob"
  endif
endfunction

function! s:suite.before()
  let s:A = vital#vital#import('Validator.Args')
endfunction

function! s:suite.__of__()
  let of = themis#suite('of')

  function! of.of_should_throw_if_it_received_non_string_value() abort
    let A = s:A
    Throws /^vital: Validator.Args: of(): expected string argument but got number/
    \ A.of(42)
    call A.of('')
    Throws /^vital: Validator.Args: of(): expected string argument but got func/
    \ A.of(function('function'))
    Throws /^vital: Validator.Args: of(): expected string argument but got list/
    \ A.of([42])
    Throws /^vital: Validator.Args: of(): expected string argument but got dict/
    \ A.of({})
    Throws /^vital: Validator.Args: of(): expected string argument but got float/
    \ A.of(3.14)
    Throws /^vital: Validator.Args: of(): expected string argument but got bool/
    \ A.of(v:false)
    call s:assert_null_support()
    Throws /^vital: Validator.Args: of(): expected string argument but got none/
    \ A.of(v:null)
    call s:assert_job_support()
    Throws /^vital: Validator.Args: of(): expected string argument but got job/
    \ A.of(test_null_job())
    call s:assert_channel_support()
    Throws /^vital: Validator.Args: of(): expected string argument but got channel/
    \ A.of(test_null_channel())
    call s:assert_blob_support()
    Throws /^vital: Validator.Args: of(): expected string argument but got blob/
    \ A.of(test_null_blob())
  endfunction

  function! of.of_should_not_validate_if_disabled() abort
    " disabled
    let v = s:A.of('func()', 0).type(v:t_string)
    try
      Assert Equals(v.validate([42]), [42])
    catch
      Assert 0, 'should not throw'
    endtry

    " enabled
    let v = s:A.of('func()', 1).type(v:t_string)
    Throws /^func(): invalid type arguments were given (expected: string, got: number)/
    \ v.validate([42])
  endfunction

  function! of.no_check()
    call s:A.of('test()').validate([])
    call s:A.of('test()').validate([1])
    call s:A.of('test()').validate([1,'foo'])
  endfunction

  function! of.validate_returns_given_args()
    let A = s:A
    Assert Equals(A.of('test()').validate([]), [])
    Assert Equals(A.of('test()').validate(['foo']), ['foo'])
    Assert Equals(
    \         A.of('test()').validate(['str', ['list'], {'value': 'dict'}]),
    \         ['str', ['list'], {'value': 'dict'}])
  endfunction

  function! of.union_types()
    let A = s:A
    Throws /^test(): invalid type arguments were given (expected: string or func, got: number)/
    \ A.of('test()').type([v:t_string, v:t_func]).validate([42])
    call A.of('test()').type([v:t_string, v:t_func]).validate([''])
    call A.of('test()').type([v:t_string, v:t_func]).validate([function('function')])
    Throws /^test(): invalid type arguments were given (expected: string or func, got: list)/
    \ A.of('test()').type([v:t_string, v:t_func]).validate([[]])
    Throws /^test(): invalid type arguments were given (expected: string or func, got: dict)/
    \ A.of('test()').type([v:t_string, v:t_func]).validate([{}])
    Throws /^test(): invalid type arguments were given (expected: string or func, got: float)/
    \ A.of('test()').type([v:t_string, v:t_func]).validate([3.14])
    Throws /^test(): invalid type arguments were given (expected: string or func, got: bool)/
    \ A.of('test()').type([v:t_string, v:t_func]).validate([v:false])
    call s:assert_null_support()
    Throws /^test(): invalid type arguments were given (expected: string or func, got: none)/
    \ A.of('test()').type([v:t_string, v:t_func]).validate([v:null])
    call s:assert_job_support()
    Throws /^test(): invalid type arguments were given (expected: string or func, got: job)/
    \ A.of('test()').type([v:t_string, v:t_func]).validate([test_null_job()])
    call s:assert_channel_support()
    Throws /^test(): invalid type arguments were given (expected: string or func, got: channel)/
    \ A.of('test()').type([v:t_string, v:t_func]).validate([test_null_channel()])
    call s:assert_blob_support()
    Throws /^test(): invalid type arguments were given (expected: string or func, got: blob)/
    \ A.of('test()').type([v:t_string, v:t_func]).validate([test_null_blob()])
  endfunction

  function! of.any_type() abort
    call s:A.of('test()').type('any').validate([42])
    call s:A.of('test()').type('any').validate([''])
    call s:A.of('test()').type('any').validate([function('function')])
    call s:A.of('test()').type('any').validate([[]])
    call s:A.of('test()').type('any').validate([{}])
    call s:A.of('test()').type('any').validate([3.14])
    call s:A.of('test()').type('any').validate([v:false])
    call s:assert_null_support()
    call s:A.of('test()').type('any').validate([v:null])
    call s:assert_job_support()
    call s:A.of('test()').type('any').validate([test_null_job()])
    call s:assert_channel_support()
    call s:A.of('test()').type('any').validate([test_null_channel()])
    call s:assert_blob_support()
    call s:A.of('test()').type('any').validate([test_null_blob()])
  endfunction

  function! of.wrong_types_and_correct_types()
    let A = s:A
    Throws /^test(): invalid type arguments were given (expected: string, got: number)/
    \ A.of('test()').type(v:t_string).validate([42])
    call A.of('test()').type(v:t_string).validate([''])
    Throws /^test(): invalid type arguments were given (expected: string, got: func)/
    \ A.of('test()').type(v:t_string).validate([function('function')])
    Throws /^test(): invalid type arguments were given (expected: string, got: list)/
    \ A.of('test()').type(v:t_string).validate([[]])
    Throws /^test(): invalid type arguments were given (expected: string, got: dict)/
    \ A.of('test()').type(v:t_string).validate([{}])
    Throws /^test(): invalid type arguments were given (expected: string, got: float)/
    \ A.of('test()').type(v:t_string).validate([3.14])
    Throws /^test(): invalid type arguments were given (expected: string, got: bool)/
    \ A.of('test()').type(v:t_string).validate([v:false])
    call s:assert_null_support()
    Throws /^test(): invalid type arguments were given (expected: string, got: none)/
    \ A.of('test()').type(v:t_string).validate([v:null])
    call s:assert_job_support()
    Throws /^test(): invalid type arguments were given (expected: string, got: job)/
    \ A.of('test()').type(v:t_string).validate([test_null_job()])
    call s:assert_channel_support()
    Throws /^test(): invalid type arguments were given (expected: string, got: channel)/
    \ A.of('test()').type(v:t_string).validate([test_null_channel()])
    call s:assert_blob_support()
    Throws /^test(): invalid type arguments were given (expected: string, got: blob)/
    \ A.of('test()').type(v:t_string).validate([test_null_blob()])
  endfunction

  function! of.validate_should_throw_if_it_received_non_list_value() abort
    let A = s:A
    Throws /^vital: Validator.Args: Validator.validate(): expected list argument but got number/
    \ A.of('test()').type('any').validate(42)
    Throws /^vital: Validator.Args: Validator.validate(): expected list argument but got string/
    \ A.of('test()').type('any').validate('')
    Throws /^vital: Validator.Args: Validator.validate(): expected list argument but got func/
    \ A.of('test()').type('any').validate(function('function'))
    call A.of('test()').type('any').validate([42])
    Throws /^vital: Validator.Args: Validator.validate(): expected list argument but got dict/
    \ A.of('test()').type('any').validate({})
    Throws /^vital: Validator.Args: Validator.validate(): expected list argument but got float/
    \ A.of('test()').type('any').validate(3.14)
    Throws /^vital: Validator.Args: Validator.validate(): expected list argument but got bool/
    \ A.of('test()').type('any').validate(v:false)
    call s:assert_null_support()
    Throws /^vital: Validator.Args: Validator.validate(): expected list argument but got none/
    \ A.of('test()').type('any').validate(v:null)
    call s:assert_job_support()
    Throws /^vital: Validator.Args: Validator.validate(): expected list argument but got job/
    \ A.of('test()').type('any').validate(test_null_job())
    call s:assert_channel_support()
    Throws /^vital: Validator.Args: Validator.validate(): expected list argument but got channel/
    \ A.of('test()').type('any').validate(test_null_channel())
    call s:assert_blob_support()
    Throws /^vital: Validator.Args: Validator.validate(): expected list argument but got blob/
    \ A.of('test()').type('any').validate(test_null_blob())
  endfunction

  function! of.arity_is_correct() abort
    call s:A.of('test()').type(v:t_string).validate(['foo'])
    call s:A.of('test()').type(v:t_string, 'option', v:t_string)
                        \.validate(['foo', 'bar'])
    call s:A.of('test()').type(v:t_string, 'option', v:t_string, v:t_string)
                        \.validate(['foo', 'bar'])
    " if the last type is optional argument, skip validation of rest arguments
    " (but if any types were given after optional argument, check the types and arity)
    call s:A.of('test()').type(v:t_string, 'option').validate(['foo'])
    call s:A.of('test()').type(v:t_string, 'option').validate(['foo', 'bar'])
    call s:A.of('test()').type(v:t_string, 'option').validate(['foo', 'bar', 'baz'])
  endfunction

  function! of.type_invalid_args() abort
    let A = s:A
    Throws /^vital: Validator.Args: Validator.type(): expected type or union types but got string/
    \ A.of('test()').type('string')
    Throws /^vital: Validator.Args: Validator.type(): expected type or union types but got number/
    \ A.of('test()').type(999)

    Throws /^vital: Validator.Args: Validator.type(): multiple optional arguments were given/
    \ A.of('test()').type('option', 'option')
  endfunction

  function! of.arity_is_wrong() abort
    let A = s:A
    Throws /^test(): too few arguments/
    \ A.of('test()').type(v:t_string, 'option').validate([])
    Throws /^test(): too few arguments/
    \ A.of('test()').type(v:t_string).validate([])
    Throws /^test(): too many arguments/
    \ A.of('test()').type(v:t_string).validate(['foo', 'bar'])
    Throws /^test(): too many arguments/
    \ A.of('test()').type(v:t_string, 'option', v:t_string)
                    \.validate(['foo', 'bar', 'baz'])
  endfunction

  function! of.assert_only() abort
    let A = s:A
    Throws /^test(): the first argument should be non empty string/
    \ A.of('test()').assert(1, 'type(v:val) is type('''') && v:val != ''''',
                   \           'the first argument should be non empty string')
                   \.validate([''])
    Throws /^test(): the 1th argument's assertion was failed/
    \ A.of('test()').assert(1, 'type(v:val) is type('''') && v:val != ''''')
                   \.validate([''])
    call
    \ A.of('test()').assert(1, 'type(v:val) is type('''') && v:val != ''''',
                   \           'the first argument should be non empty string')
                   \.validate(['foo'])
  endfunction

  function! of.assert_invalid_args() abort
    let A = s:A
    Throws /^vital: Validator.Args: Validator.assert(): the first argument number was not positive/
    \ A.of('test()').assert(-1, 'v:val != ''''',
                   \            'the first argument should be non empty string')
    Throws /^vital: Validator.Args: Validator.assert(): the first argument number was not positive/
    \ A.of('test()').assert(0, 'v:val != ''''',
                   \            'the first argument should be non empty string')
    " TODO: is type check necessary?
  endfunction

  function! of.assert_with_type() abort
    let A = s:A
    Throws /^test(): the first argument should be non empty string/
    \ A.of('test()').type(v:t_string)
                   \.assert(1, 'v:val != ''''',
                   \            'the first argument should be non empty string')
                   \.validate([''])
    Throws /^test(): the 1th argument's assertion was failed/
    \ A.of('test()').type(v:t_string)
                   \.assert(1, 'v:val != ''''')
                   \.validate([''])
    call
    \ A.of('test()').type(v:t_string)
                   \.assert(1, 'v:val != ''''',
                   \            'the first argument should be non empty string')
                   \.validate(['foo'])
  endfunction

  function! of.mixed_validation_with_assert_and_type() abort
    let A = s:A
    " .type() checking failure
    Throws /^test(): invalid type arguments were given (expected: string, got: number)/
    \ A.of('test()').type(v:t_string)
                   \.assert(1, 'v:val != ''''',
                   \            'the first argument should be non empty string')
                   \.validate([42])
    " too few arguments
    Throws /^test(): too few arguments/
    \ A.of('test()').type(v:t_string)
                   \.assert(1, 'v:val != ''''',
                   \            'the first argument should be non empty string')
                   \.validate([])
    " too many arguments
    Throws /^test(): too many arguments/
    \ A.of('test()').type(v:t_string)
                   \.assert(1, 'v:val != ''''',
                   \            'the first argument should be non empty string')
                   \.validate(['foo', 'bar'])
    " type() with optional argument, and assert()
    call
    \ A.of('test()').type(v:t_string, 'option')
                   \.assert(1, 'v:val != ''''',
                   \            'the first argument should be non empty string')
                   \.assert(2, 'v:val != ''''',
                   \            'the second argument should be non empty string')
                   \.validate(['foo', 'bar'])
    Throws /^test(): the second argument should be non empty string/
    \ A.of('test()').type(v:t_string, 'option')
                   \.assert(1, 'v:val != ''''',
                   \            'the first argument should be non empty string')
                   \.assert(2, 'v:val != ''''',
                   \            'the second argument should be non empty string')
                   \.validate(['foo', ''])
    call
    \ A.of('test()').type(v:t_string, 'option', v:t_string)
                   \.assert(1, 'v:val != ''''',
                   \            'the first argument should be non empty string')
                   \.assert(2, 'v:val != ''''',
                   \            'the second argument should be non empty string')
                   \.validate(['foo', 'bar'])
    Throws /^test(): the second argument should be non empty string/
    \ A.of('test()').type(v:t_string, 'option', v:t_string)
                   \.assert(1, 'v:val != ''''',
                   \            'the first argument should be non empty string')
                   \.assert(2, 'v:val != ''''',
                   \            'the second argument should be non empty string')
                   \.validate(['foo', ''])
  endfunction

  function! of.assert_no_out_of_range()
    let A = s:A
    Throws /^vital: Validator.Args: Validator.assert(): the first argument number was out of range (type() defines 1 arguments)/
    \ A.of('test()').type(v:t_string)
                   \.assert(1, 'v:val != ''''',
                   \            'the first argument should be non empty string')
                   \.assert(2, 'v:val != ''''',
                   \            'the second argument?')
    Throws /^vital: Validator.Args: Validator.assert(): the first argument number was out of range (type() defines 1 arguments)/
    \ A.of('test()').assert(1, 'v:val != ''''',
                   \            'the first argument should be non empty string')
                   \.assert(2, 'v:val != ''''',
                   \            'the second argument?')
                   \.type(v:t_string)
    Throws /^vital: Validator.Args: Validator.assert(): the first argument number was out of range (type() defines 1-2 arguments)/
    \ A.of('test()').type(v:t_string, 'option', v:t_string)
                   \.assert(1, 'v:val != ''''',
                   \            'the first argument should be non empty string')
                   \.assert(2, 'v:val != ''''',
                   \            'the second argument should be non empty string')
                   \.assert(3, 'v:val != ''''',
                   \            'the third argument?')
    Throws /^vital: Validator.Args: Validator.assert(): the first argument number was out of range (type() defines 1-2 arguments)/
    \ A.of('test()').assert(1, 'v:val != ''''',
                   \            'the first argument should be non empty string')
                   \.assert(2, 'v:val != ''''',
                   \            'the second argument should be non empty string')
                   \.assert(3, 'v:val != ''''',
                   \            'the third argument?')
                   \.type(v:t_string, 'option', v:t_string)
    Throws /^vital: Validator.Args: Validator.assert(): the first argument number was out of range (type() defines 1-3 arguments)/
    \ A.of('test()').assert(1, 'v:val != ''''',
                   \            'the first argument should be non empty string')
                   \.assert(2, 'v:val != ''''',
                   \            'the second argument should be non empty string')
                   \.assert(3, 'v:val != ''''',
                   \            'the third argument should be non empty string')
                   \.assert(4, 'v:val != ''''',
                   \            'the fourth argument?')
                   \.type(v:t_string, 'option', v:t_string, v:t_string)
  endfunction

endfunction
