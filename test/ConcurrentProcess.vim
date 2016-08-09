scriptencoding utf-8

let s:suite = themis#suite('ConcurrentProcess')
let s:assert = themis#helper('assert')

function! s:suite.before()
  let s:CP = vital#vital#new().import('ConcurrentProcess')
endfunction

function! s:suite.before_each() abort
  if !s:CP.is_available()
    call s:assert.skip('CP is not available. Do you have vimproc?')
  endif
  if !executable('cat') || !executable('sh')
    call s:assert.skip("'cat' or 'sh' are not available. Check your $PATH.")
  endif
endfunction

function! s:suite.after()
  unlet! s:CP
endfunction

function! s:suite.of()
  " Well, this also has tick() and log_dump()
  " This may depend on performance of computer as well
  let label = s:CP.of('cat -n', '/tmp', [
        \ ['*writeln*', 'hello'],
        \ ['*read*', 'x', '']])
  call s:assert.is_string(label)

  " dirty hack
  sleep
  call s:CP.tick(label)
  sleep
  call s:CP.tick(label)
  sleep
  call s:CP.tick(label)

  call s:CP.tick(label)
  redir => output
    silent call s:CP.log_dump(label)
  redir END
  call s:assert.match(output, '1\s\+hello')
endfunction

function! s:suite.of_with_failure()
  try
    call s:CP.of('this-command-does-not-exist', '', [])
    call s:assert.fail('of')
  catch /File "this-command-does-not-exist" is not found/
    call s:assert.true(1)
    return
  endtry
  call s:assert.fail('of')
endfunction

function! s:suite.consume()
  " Well, this also has of(), and tick()
  " This may depend on performance of computer as well
  let label = s:CP.of('cat -n', '/tmp', [
        \ ['*writeln*', 'hello'],
        \ ['*read*', 'x', ''],
        \ ['*writeln*', 'world'],
        \ ['*read*', 'y', '']])
  call s:CP.tick(label)

  " dirty hack
  sleep
  call s:CP.tick(label)
  sleep
  call s:CP.tick(label)
  sleep
  call s:CP.tick(label)

  let [outx, errx] = s:CP.consume(label, 'x')
  let [outy, erry] = s:CP.consume(label, 'y')

  call s:assert.match(outx, '1\s\+hello')
  call s:assert.not_match(outx, '2\s\+world')

  call s:assert.not_match(outy, '1\s\+hello')
  call s:assert.match(outy, '2\s\+world')

  call s:assert.equals(errx, '')
  call s:assert.equals(erry, '')

  " 2nd time is different.
  let [out, err] = s:CP.consume(label, 'x')
  call s:assert.equals(out, '')
  call s:assert.equals(err, '')

  let [out, err] = s:CP.consume(label, 'y')
  call s:assert.equals(out, '')
  call s:assert.equals(err, '')
endfunction

function! s:suite.consume_all_blocking()
  let label = s:CP.of('sh -c "sleep 2; echo -n done; sleep 2"', '/tmp', [
        \ ['*read*', 'x', 'done']])

  call s:assert.false(s:CP.is_done(label, 'x'))

  " with very little timeout value
  let [out, err, timedout_p] = s:CP.consume_all_blocking(label, 'x', 1)
  call s:assert.true(timedout_p)
  call s:assert.false(s:CP.is_done(label, 'x'))

  " with enough timeout value
  let [out, err, timedout_p] = s:CP.consume_all_blocking(label, 'x', 10)
  call s:assert.false(timedout_p)
  call s:assert.true(s:CP.is_done(label, 'x'))
endfunction

function! s:suite.read_all()
  " system() pattern -- execute something and get everything.
  let label = s:CP.of('sh -c "sleep 1; echo done; sleep 1"', '', [
        \ ['*read-all*', 'x']])

  let [out, err, timedout_p] = s:CP.consume_all_blocking(label, 'x', 10)
  call s:assert.equals(out, "done\n")
  call s:assert.false(timedout_p)
endfunction
