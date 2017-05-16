scriptencoding utf-8

let s:suite = themis#suite('Validator.Args')
let s:assert = themis#helper('assert')

function! s:suite.before()
  let s:A = vital#vital#import('Validator.Args')
  let s:T = s:A.TYPE
endfunction

function! s:suite.__of__()
  let of = themis#suite('of')

  function! of.of_should_throw_if_it_received_non_string_value() abort
    let [A, T] = [s:A, s:T]
    Throws /^Validator.Args: of(): expected String argument but got Number/
    \ A.of(42)
    call A.of('')
    Throws /^Validator.Args: of(): expected String argument but got Funcref/
    \ A.of(function('function'))
    Throws /^Validator.Args: of(): expected String argument but got List/
    \ A.of([42])
    Throws /^Validator.Args: of(): expected String argument but got Dictionary/
    \ A.of({})
    Throws /^Validator.Args: of(): expected String argument but got Float/
    \ A.of(3.14)
    if v:version >= 800
      Throws /^Validator.Args: of(): expected String argument but got Bool/
      \ A.of(v:false)
      Throws /^Validator.Args: of(): expected String argument but got None/
      \ A.of(v:null)
      " TODO: job, channel
    endif
  endfunction

  function! of.no_check()
    let A = s:A
    call A.of('test()').validate([])
    call A.of('test()').validate([1])
    call A.of('test()').validate([1,'foo'])
  endfunction

  function! of.union_types()
    let [A, T] = [s:A, s:T]
    Throws /^test(): invalid type arguments were given (expected: String or Funcref, got: Number)/
    \ A.of('test()').type([T.STRING, T.FUNC]).validate([42])
    call A.of('test()').type([T.STRING, T.FUNC]).validate([''])
    call A.of('test()').type([T.STRING, T.FUNC]).validate([function('function')])
    Throws /^test(): invalid type arguments were given (expected: String or Funcref, got: List)/
    \ A.of('test()').type([T.STRING, T.FUNC]).validate([[]])
    Throws /^test(): invalid type arguments were given (expected: String or Funcref, got: Dictionary)/
    \ A.of('test()').type([T.STRING, T.FUNC]).validate([{}])
    Throws /^test(): invalid type arguments were given (expected: String or Funcref, got: Float)/
    \ A.of('test()').type([T.STRING, T.FUNC]).validate([3.14])
    if v:version >= 800
      Throws /^test(): invalid type arguments were given (expected: String or Funcref, got: Bool)/
      \ A.of('test()').type([T.STRING, T.FUNC]).validate([v:false])
      Throws /^test(): invalid type arguments were given (expected: String or Funcref, got: None)/
      \ A.of('test()').type([T.STRING, T.FUNC]).validate([v:null])
      " TODO: job, channel
    endif
  endfunction

  function! of.any_type() abort
    let [A, T] = [s:A, s:T]
    call A.of('test()').type(T.ANY).validate([42])
    call A.of('test()').type(T.ANY).validate([''])
    call A.of('test()').type(T.ANY).validate([function('function')])
    call A.of('test()').type(T.ANY).validate([[]])
    call A.of('test()').type(T.ANY).validate([{}])
    call A.of('test()').type(T.ANY).validate([3.14])
    if v:version >= 800
      call A.of('test()').type(T.ANY).validate([v:false])
      call A.of('test()').type(T.ANY).validate([v:null])
      " TODO: job, channel
    endif
  endfunction

  function! of.wrong_types_and_correct_types()
    let [A, T] = [s:A, s:T]
    Throws /^test(): invalid type arguments were given (expected: String, got: Number)/
    \ A.of('test()').type(T.STRING).validate([42])
    call A.of('test()').type(T.STRING).validate([''])
    Throws /^test(): invalid type arguments were given (expected: String, got: Funcref)/
    \ A.of('test()').type(T.STRING).validate([function('function')])
    Throws /^test(): invalid type arguments were given (expected: String, got: List)/
    \ A.of('test()').type(T.STRING).validate([[]])
    Throws /^test(): invalid type arguments were given (expected: String, got: Dictionary)/
    \ A.of('test()').type(T.STRING).validate([{}])
    Throws /^test(): invalid type arguments were given (expected: String, got: Float)/
    \ A.of('test()').type(T.STRING).validate([3.14])
    if v:version >= 800
      Throws /^test(): invalid type arguments were given (expected: String, got: Bool)/
      \ A.of('test()').type(T.STRING).validate([v:false])
      Throws /^test(): invalid type arguments were given (expected: String, got: None)/
      \ A.of('test()').type(T.STRING).validate([v:null])
      " TODO: job, channel
    endif
  endfunction

  function! of.validate_should_throw_if_it_received_non_list_value() abort
    let [A, T] = [s:A, s:T]
    Throws /^Validator.Args: Validator.validate(): expected List argument but got Number/
    \ A.of('test()').type(T.ANY).validate(42)
    Throws /^Validator.Args: Validator.validate(): expected List argument but got String/
    \ A.of('test()').type(T.ANY).validate('')
    Throws /^Validator.Args: Validator.validate(): expected List argument but got Funcref/
    \ A.of('test()').type(T.ANY).validate(function('function'))
    call A.of('test()').type(T.ANY).validate([42])
    Throws /^Validator.Args: Validator.validate(): expected List argument but got Dictionary/
    \ A.of('test()').type(T.ANY).validate({})
    Throws /^Validator.Args: Validator.validate(): expected List argument but got Float/
    \ A.of('test()').type(T.ANY).validate(3.14)
    if v:version >= 800
      Throws /^Validator.Args: Validator.validate(): expected List argument but got Bool/
      \ A.of('test()').type(T.ANY).validate(v:false)
      Throws /^Validator.Args: Validator.validate(): expected List argument but got None/
      \ A.of('test()').type(T.ANY).validate(v:null)
      " TODO: job, channel
    endif
  endfunction

  function! of.arity_is_correct() abort
    let [A, T] = [s:A, s:T]
    call A.of('test()').type(T.STRING).validate(['foo'])
    call A.of('test()').type(T.STRING, T.OPTARG, T.STRING)
                        \.validate(['foo', 'bar'])
    call A.of('test()').type(T.STRING, T.OPTARG, T.STRING, T.STRING)
                        \.validate(['foo', 'bar'])
    " if the last type is OPTARG, skip validation of rest arguments
    call A.of('test()').type(T.STRING, T.OPTARG).validate(['foo'])
    call A.of('test()').type(T.STRING, T.OPTARG).validate(['foo', 'bar'])
    call A.of('test()').type(T.STRING, T.OPTARG).validate(['foo', 'bar', 'baz'])
  endfunction

  function! of.arity_is_wrong() abort
    let [A, T] = [s:A, s:T]
    Throws /^test(): too few arguments/
    \ A.of('test()').type(T.STRING, T.OPTARG).validate([])
    Throws /^test(): too few arguments/
    \ A.of('test()').type(T.STRING).validate([])
    Throws /^test(): too many arguments/
    \ A.of('test()').type(T.STRING).validate(['foo', 'bar'])
    Throws /^test(): too many arguments/
    \ A.of('test()').type(T.STRING, T.OPTARG, T.STRING)
                    \.validate(['foo', 'bar', 'baz'])
  endfunction
endfunction
