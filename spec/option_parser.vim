scriptencoding utf-8
source spec/base.vim

let g:V = vital#of('vital')
let g:O = g:V.import('OptionParser')

function! s:permutation(args)
  if len(a:args) <= 1
    return [[a:args[0]]]
  endif

  let ret = []
  for a in a:args
    let xs = filter(copy(a:args), 'type(v:val) != type(a) || v:val != a')
    let perms = s:permutation(xs)
    call extend(ret, map(perms, '[a] + v:val'))
    unlet a
  endfor
  return ret
endfunction

function! CompleteTest(optlead, cmdline, pos)
  return filter(['sushi', 'yakiniku', 'yakitori'], 'a:optlead == "" ? 1 : (v:val =~# "^" . a:optlead)')
endfunction

function! CompleteTest2(optlead, cmdline, pos)
  return filter(['inu', 'manbou', 'momonga'], 'a:optlead == "" ? 1 : (v:val =~# "^" . a:optlead)')
endfunction

function! CompleteUnknownOptionTest(optlead, cmdline, pos)
  return filter(['vim', 'vimmer', 'kowai'], 'a:optlead == "" ? 1 : (v:val =~# "^" . a:optlead)')
endfunction

Context OptionParser.new()

  It makes parser object
    let o = g:O.new()
    let func_type = type(function('empty'))
    Should has_key(o, 'options')
    Should type(o.options) == type({})
    Should has_key(o, 'on')
    Should type(o.on) == func_type
    Should has_key(o, 'parse')
    Should type(o.parse) == func_type
    Should has_key(o, 'help')
    Should type(o.help) == func_type
    Should has_key(o, 'complete')
    Should type(o.help) == func_type
  End

End

Context on() funcref in OptionParser object
  It defines "--hoge" options with on()
    let o = g:O.new()
    call o.on('--hoge', 'huga')
    Should has_key(o.options, 'hoge')
    Should o.options.hoge == {'description': 'huga', 'definition': '--hoge'}
    " non alphabetical characters
    call o.on('--!"#$?', 'huga')
    Should has_key(o.options, '!"#$?')
    Should o.options['!"#$?'] == {'description': 'huga', 'definition': '--!"#$?'}
  End

  It defines short option
    let o = g:O.new()

    call o.on('--hoge', 'huga', {'short' : '-h'})
    Should has_key(o.options.hoge, 'short_option_definition')
    Should o.options.hoge.short_option_definition ==# '-h'

    " non alphabetical characters
    for na in ['!', '"', '#', '$', '%', '&', '''', '(', ')', '~', '\', '[', ']', ';', ':', '+', '*', ',', '.', '/', '1', '2', '_']
        call o.on('--' . na, 'huga', {'short' : '-' . na})
        Should has_key(o.options[na], 'short_option_definition')
        Should o.options[na].short_option_definition ==# '-'.na
    endfor
  End

  It defines --hoge=VALUE option
    let o = g:O.new()

    call o.on('--hoge=VALUE', 'huga')
    Should has_key(o.options, 'hoge')
    Should o.options.hoge == {'description': 'huga', 'definition': '--hoge=VALUE', 'has_value': 1}
  End

  It defines --[no-]hoge option
    let o = g:O.new()
    call o.on('--[no-]hoge', 'huga')
    Should has_key(o.options, 'hoge')
    Should o.options.hoge == {'description': 'huga', 'definition': '--[no-]hoge', 'no': 1}
  End

  It can chain definitions of options
    let o = g:O.new()
    call o.on('--hoge', '')
         \.on('--huga', '')
         \.on('--piyo', '')
         \.on('--poyo', '')
    Should has_key(o.options, 'hoge')
    Should has_key(o.options, 'huga')
    Should has_key(o.options, 'piyo')
    Should has_key(o.options, 'poyo')
  End

  It occurs an error when invalid option name is specified
    let o = g:O.new()
    ShouldThrow o.on('invalid_name', ''), /.*/
    ShouldThrow o.on('--invalid name', ''), /.*/
  End

  It occurs an error when invalid short option name is specified
    let o = g:O.new()
    ShouldThrow o.on('--valid', '-but_invalid', ''), /.*/
    ShouldThrow o.on('--valid', '--', ''), /.*/
    ShouldThrow o.on('--valid', 'a', ''), /.*/
    ShouldThrow o.on('--valid', '-=', ''), /.*/
    ShouldThrow o.on('--valid', '- ', ''), /.*/
  End

  It sets default values if specified
    let o = g:O.new()
    call o.on('--hoge', '')
         \.on('--huga', '', {'default' : 3})
         \.on('--tsura', '', 'aaa')
         \.on('--poyo', 'a', 3)
    Should ! has_key(o.options.hoge, 'default_value')
    Should has_key(o.options.huga, 'default_value')
    Should o.options.huga.default_value == 3
    Should has_key(o.options.tsura, 'default_value')
    Should o.options.tsura.default_value == 'aaa'
    Should has_key(o.options.poyo, 'default_value')
    Should o.options.poyo.default_value == 3
  End

  It sets function for completion with "completion" key
    let o = g:O.new()
    call o.on('--hoge', '', {'completion' : 'file'})
         \.on('--huga', '', {'completion' : function('CompleteTest')})
         \.on('--piyo', '')
    Should has_key(o.options.hoge, 'completion')
    Should has_key(o.options.huga, 'completion')
    Should ! has_key(o.options.piyo, 'completion')
    Should type(o.options.hoge.completion) == type(function('empty'))
    Should type(o.options.huga.completion) == type(function('empty'))
  End
End

Context parse() in OptionParser object

  It parses empty argument
    let o = g:O.new()
    Should o.parse('') == {'__unknown_args__' : []}
  End

  It deals with <bang>
    let o = g:O.new()
    Should o.parse('', '!') == {'__unknown_args__' : [], '__bang__' : '!'}
  End

  It deals with <count>
    let o = g:O.new()
    Should o.parse('', 3) == {'__unknown_args__' : [], '__count__' : 3}
  End

  It deals with <reg>
    let o = g:O.new()
    Should o.parse('', 'g') == {'__unknown_args__' : [], '__reg__' : 'g'}
  End

  It deals with <range>
    let o = g:O.new()
    Should o.parse('', [1, 100]) == {'__unknown_args__' : [], '__range__' : [1, 100]}
  End

  It deals with command special options regardless of the order of and number of arguments
    let o = g:O.new()
    " count command
    let cands = ['g', 42, '!']
    let perms = s:permutation(cands)
    for p in perms
      Should call(o.parse, [''] + p, o) == {'__unknown_args__' : [], '__count__' : 42, '__bang__' : '!', '__reg__' : 'g'}
    endfor

    " range command
    let cands = ['g', [1, 100], '!']
    let perms = s:permutation(cands)
    for p in perms
      Should call(o.parse, [''] + p, o) == {'__unknown_args__' : [], '__range__' : [1, 100], '__bang__' : '!', '__reg__' : 'g'}
    endfor
  End

  It parses --hoge as 'hoge' : 1
    let o = g:O.new()
    call o.on('--hoge', 'huga')
    Should o.parse('--hoge') == {'__unknown_args__' : [], 'hoge' : 1}
  End

  It parses --hoge=VALUE as 'hoge' : 'VALUE' and echoes an error when VALUE is omitted
    let o = g:O.new()
    call o.on('--hoge=VALUE', 'huga')
    Should o.parse('--hoge=huga') == {'__unknown_args__' : [], 'hoge' : 'huga'}
    ShouldThrow g:O.parse('--hoge'), /.*/
  End

  It parses --[no-]hoge as 'hoge' : 0 or 1
    let o = g:O.new()
    call o.on('--[no-]hoge', 'huga')
    Should o.parse('--no-hoge') == {'__unknown_args__' : [], 'hoge' : 0}
    Should o.parse('--hoge') == {'__unknown_args__' : [], 'hoge' : 1}
  End

  It parses short option -h as 'hoge'
    let o = g:O.new()
    call o.on('--hoge', 'huga', {'short' : '-h'})
    Should o.parse('-h') == {'__unknown_args__' : [], 'hoge' : 1}
    Should o.parse('--hoge') == {'__unknown_args__' : [], 'hoge' : 1}
  End

  It parses default values if they are set in on() and they are not specified by user
    let o = g:O.new()
    call o.on('--hoge', '', {'default' : 3.14})
    call o.on('--huga', '', 'default value')
    Should o.parse('') == {'__unknown_args__' : [], 'hoge' : 3.14, 'huga' : 'default value'}
    Should o.parse('--hoge --huga --piyo') == {'__unknown_args__' : ['--piyo'], 'hoge' : 1, 'huga' : 1}
  End

  It doesn't parse arguments not defined with on()
    let o = g:O.new()
    call o.on('--foo', 'huga')
    call o.on('--bar=VALUE', 'huga')
    call o.on('--[no-]baz', 'huga')
    Should o.parse('--hoge') == {'__unknown_args__' : ['--hoge']}
    Should o.parse('--huga=poyo') == {'__unknown_args__' : ['--huga=poyo']}
    Should o.parse('--no-poyo') == {'__unknown_args__' : ['--no-poyo']}
    Should o.parse('--hoge --huga=poyo --no-poyo') == {'__unknown_args__' : ['--hoge', '--huga=poyo', '--no-poyo']}
  End

  It parses all argument types at one time regardless of the order of arguments
    let o = g:O.new()
    call o.on('--hoge', '')
    call o.on('--huga=VALUE', '')
    call o.on('--[no-]poyo', '')
    call o.on('--piyo', '', {'default' : 'aaa'})
    let args = ['--hoge', '--huga=foo', '--no-poyo', 'unknown_arg']
    let perms = s:permutation(args)
    for p in perms
      Should o.parse(join(p, ' ')) ==
            \ {'__unknown_args__' : ['unknown_arg'], 'hoge' : 1, 'huga' : 'foo', 'poyo' : 0, 'piyo' : 'aaa'}
    endfor
  End

  It parses all options defined with on() and command options at one time regardless of the order of arguments
    let o = g:O.new()
    call o.on('--hoge', '')
    call o.on('--huga=VALUE', '')
    call o.on('--tsura', '', {'short' : '-t'})
    call o.on('--[no-]poyo', '')
    call o.on('--piyo', '', {'default' : 42})
    call o.on('--puyo', '', 3.14)
    let args = map(s:permutation(['--hoge', '--huga=foo', '--no-poyo', '-t', 'unknown_arg']), 'join(v:val, " ")')
    let opts_count = s:permutation(['g', 42, '!'])
    let opts_range = s:permutation(['g', [1, 100], '!'])

    " command with <count>
    for a in args
      for oc in opts_count
        Should call(o.parse, [a] + oc, o) ==
              \ {
              \   '__unknown_args__' : ['unknown_arg'],
              \   '__count__' : 42,
              \   '__bang__' : '!',
              \   '__reg__' : 'g',
              \   'hoge' : 1,
              \   'huga' : 'foo',
              \   'tsura' : 1,
              \   'poyo' : 0,
              \   'piyo' : 42,
              \   'puyo' : 3.14,
              \ }
      endfor
    endfor

    " command with <range>
    for a in args
      for or in opts_range
        Should call(o.parse, [a] + or, o) ==
              \ {
              \   '__unknown_args__' : ['unknown_arg'],
              \   '__range__' : [1, 100],
              \   '__bang__' : '!',
              \   '__reg__' : 'g',
              \   'hoge' : 1,
              \   'huga' : 'foo',
              \   'tsura' : 1,
              \   'poyo' : 0,
              \   'piyo' : 42,
              \   'puyo' : 3.14,
              \ }
      endfor
    endfor
  End

  It 'can parse some non alphabetical names and keys'
    let o = g:O.new()
    call o.on('--''!"#$=VALUE', '')
    Should o.parse('--''!"#$=''hoge''') == {'__unknown_args__' : [], '''!"#$' : "'hoge'"}
  End

End


Context help() funcref in OptionParser object

  It returns help message
    let o = g:O.new()
    call o.on('--hoge=VALUE', 'description of hoge, must have value')
    call o.on('--foo', 'description of foo')
    call o.on('--[no-]bar', 'description of bar, contradictable')
    call o.on('--baz', 'description of baz, has short option', {'short' : '-b'})
    call o.on('--qux', 'description of qux, has default value', {'default' : 3.14})

    Should o.help() ==# join([
          \   "Options:",
          \   "  --foo        : description of foo",
          \   "  --baz, -b    : description of baz, has short option",
          \   "  --hoge=VALUE : description of hoge, must have value",
          \   "  --[no-]bar   : description of bar, contradictable",
          \   "  --qux        : description of qux, has default value (DEFAULT: 3.14)",
          \ ], "\n")
  End

  It returns title-only help if no option is defined
    let o = g:O.new()
    Should o.help() ==# "Options:\n"
  End

End

Context complete() funcref in OptionParser object

    It completes long options
        let o = g:O.new()
        call o.on('--[no-]huga=VALUE', '', {'short' : '-h', 'completion' : function('CompleteTest')})
             \.on('--hoge', '')
             \.on('--piyo', '', {'short' : '-p'})
             \.on('--tsura=VALUE', '', {'completion' : function('CompleteTest2')})
             \.on('--[no-]poyo', '')
        let o.unknown_options_completion = function('CompleteUnknownOptionTest')
        Should o.complete('--', 'Hoge --', 7) == ['--tsura=', '--hoge', '--huga=', '--no-huga=', '--piyo', '--poyo', '--no-poyo']
        Should o.complete('--h', 'Hoge --h', 8) == ['--hoge', '--huga=']
        Should o.complete('--hu', 'Hoge --hu', 9) == ['--huga=']
        Should o.complete('--ho', 'Hoge --ho', 9) == ['--hoge']
        Should o.complete('--p', 'Hoge --p', 8) == ['--piyo', '--poyo']
        Should o.complete('--po', 'Hoge --po', 9) == ['--poyo']
        Should o.complete('--pi', 'Hoge --pi', 9) == ['--piyo']
        Should o.complete('--f', 'Hoge --f', 8) == []
        Should o.complete('--no', 'Hoge --no', 9) == ['--no-huga=', '--no-poyo']
    End

    It completes short options
        let o = g:O.new()
        call o.on('--[no-]huga=VALUE', '', {'short' : '-h', 'completion' : function('CompleteTest')})
             \.on('--hoge', '')
             \.on('--piyo', '', {'short' : '-p'})
             \.on('--tsura=VALUE', '', {'completion' : function('CompleteTest2')})
             \.on('--[no-]poyo', '')
        let o.unknown_options_completion = function('CompleteUnknownOptionTest')
        Should o.complete('-', 'Hoge -', 6) == ['-h=', '-no-h=', '-p']
        Should o.complete('-h', 'Hoge -h', 7) == ['-h=']
        Should o.complete('-p', 'Hoge -p', 7) == ['-p']
        Should o.complete('-f', 'Hoge -f', 7) == []
    End

    It completes values of options with specified complete function
        let o = g:O.new()
        call o.on('--[no-]huga=VALUE', '', {'short' : '-h', 'completion' : function('CompleteTest')})
             \.on('--hoge', '')
             \.on('--piyo', '', {'short' : '-p'})
             \.on('--tsura=VALUE', '', {'completion' : function('CompleteTest2')})
             \.on('--[no-]poyo', '')
        let o.unknown_options_completion = function('CompleteUnknownOptionTest')
        Should o.complete('--huga=', 'Hoge --huga=', 12) == ['--huga=sushi', '--huga=yakiniku', '--huga=yakitori']
        Should o.complete('--huga=yaki', 'Hoge --hoge=yaki', 16) == ['--huga=yakiniku', '--huga=yakitori']
        Should o.complete('--tsura=', 'Hoge --tsura=', 13) == ['--tsura=inu', '--tsura=manbou', '--tsura=momonga']
        Should o.complete('--hoge=', 'Hoge --hoge=', 12) == []
    End

    It completes unknown argument if "unknown_options_completion" is specified
        let o = g:O.new()
        call o.on('--[no-]huga=VALUE', '', {'short' : '-h', 'completion' : function('CompleteTest')})
             \.on('--hoge', '')
             \.on('--piyo', '', {'short' : '-p'})
             \.on('--tsura=VALUE', '', {'completion' : function('CompleteTest2')})
             \.on('--[no-]poyo', '')
        let o.unknown_options_completion = function('CompleteUnknownOptionTest')
        Should o.complete('', 'Hoge ', 5) == ['vim', 'vimmer', 'kowai']
        Should o.complete('vim', 'Hoge vim', 8) == ['vim', 'vimmer']
    End
End

Context complete_greedily() funcref in OptionParser object
    It completes all kinds of candidates
        let o = g:O.new()
        call o.on('--[no-]huga=VALUE', '', {'short' : '-h', 'completion' : function('CompleteTest')})
             \.on('--hoge', '')
             \.on('--piyo', '', {'short' : '-p'})
             \.on('--tsura=VALUE', '', {'completion' : function('CompleteTest2')})
             \.on('--[no-]poyo', '')
        let o.unknown_options_completion = function('CompleteUnknownOptionTest')
        Should o.complete_greedily('--', 'Hoge --', 7) == ['--tsura=', '--hoge', '--huga=', '--no-huga=', '--piyo', '--poyo', '--no-poyo']
        Should o.complete_greedily('--h', 'Hoge --h', 8) == ['--hoge', '--huga=']
        Should o.complete_greedily('--hu', 'Hoge --hu', 9) == ['--huga=']
        Should o.complete_greedily('--ho', 'Hoge --ho', 9) == ['--hoge']
        Should o.complete_greedily('--p', 'Hoge --p', 8) == ['--piyo', '--poyo']
        Should o.complete_greedily('--po', 'Hoge --po', 9) == ['--poyo']
        Should o.complete_greedily('--pi', 'Hoge --pi', 9) == ['--piyo']
        Should o.complete_greedily('--f', 'Hoge --f', 8) == []
        Should o.complete_greedily('--no', 'Hoge --no', 9) == ['--no-huga=', '--no-poyo']
        Should o.complete_greedily('-', 'Hoge -', 6) == ['--tsura=', '--hoge', '--huga=', '--no-huga=', '--piyo', '--poyo', '--no-poyo']
        Should o.complete_greedily('-h', 'Hoge -h', 7) == []
        Should o.complete_greedily('-p', 'Hoge -p', 7) == []
        Should o.complete_greedily('-f', 'Hoge -f', 7) == []
        Should o.complete_greedily('', 'Hoge ', 5) == ['--tsura=', '--hoge', '--huga=', '--no-huga=', '--piyo', '--poyo', '--no-poyo', 'vim', 'vimmer', 'kowai']
    End
End
