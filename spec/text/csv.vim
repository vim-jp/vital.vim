source spec/base.vim

let g:CSV = vital#of('vital').import('Text.CSV')
let g:sample_file = expand('<sfile>:p:h') . '/csv-sample.txt'
let g:expect_data = [
\   ['foo', 'bar'],
\   ['foo', 'bar'],
\   [],
\   [' '],
\   ["\t"],
\   [' ', 'bar'],
\   ['foo', ' '],
\   ['', ''],
\   ['', ''],
\   ['', ''],
\   ['foo"bar', 'baz'],
\   ['"foobar', 'baz'],
\   ['foobar"', 'baz'],
\   ['"foobar"', 'baz'],
\   ['foo,bar', 'baz'],
\   [',foobar', 'baz'],
\   ['foobar,', 'baz'],
\   [',foobar,', 'baz'],
\ ]

Context Text.CSV.parse()
  It parses records of CSV
    let csv_data = join(readfile(g:sample_file), "\n")
    Should g:expect_data ==# g:CSV.parse(csv_data)
  End
End

Context Text.CSV.parse_record()
  It parses an CSV file
    let csv_record = readfile(g:sample_file, 0, 1)[0]
    let expect_record = [
    \ ['foo', 'bar'],
    \ ['foo', 'bar'],
    \]
    Should expect_record ==# g:CSV.parse_record(csv_record)
  End
  It throws an exception when invalid data was passed
    try
      " unclosed double-quote.
      call g:CSV.parse_record('"foo')
      Should [0, 'g:CSV.parse_record(''"foo'')'][0]
    catch /^vital: Text\.CSV:/
      Should 1
    endtry

    try
      " unclosed double-quote.
      call g:CSV.parse_record('foo"')
      Should [0, 'g:CSV.parse_record(''foo"'')'][0]
    catch /^vital: Text\.CSV:/
      Should 1
    endtry

    try
      " The line which has double-quote(s) or comma(s)
      " must be wrapped by double-quotes.
      call g:CSV.parse_record('foo"bar')
      Should [0, 'g:CSV.parse_record(''foo"bar'')'][0]
    catch /^vital: Text\.CSV:/
      Should 1
    endtry

    try
      " The line which has double-quote(s) or comma(s)
      " must be wrapped by double-quotes.
      call g:CSV.parse_record('foo,bar')
      Should [0, 'g:CSV.parse_record(''foo,bar'')'][0]
    catch /^vital: Text\.CSV:/
      Should 1
    endtry
  End
End

Context Text.CSV.parse_file()
  It parses an CSV file
    Should g:expect_data ==# g:CSV.parse_file(g:sample_file)
  End
End

Context Text.CSV.dump()
  It converts a list objects to a CSV string
    Should join(readfile(g:sample_file), "\n") ==# g:CSV.dump(g:expect_data)
  End
  It converts an object to a CSV string
    Should readfile(g:sample_file)[0] ==# g:CSV.dump(g:expect_data[0])
  End
End

Context Text.CSV.dump_file()
  It dumps the data to a file
    let tempfile = tempname()
    try
      call g:CSV.dump_file(g:expect_data, tempfile)
      Should readfile(g:sample_file) ==# readfile(tempfile)
    catch
      execute 'Should [0, ' . string(v:exception) . '][0]'
    finally
      if filereadable(tempfile)
        call delete(tempfile)
      endif
    endtry
  End
  It can append the data to a file
    let tempfile = tempname()
    try
      let sample = readfile(g:sample_file)
      call g:CSV.dump_file(g:expect_data[0], tempfile)
      Should sample[0 : 0] ==# readfile(tempfile)
      call g:CSV.dump_file(g:expect_data[1], tempfile, 1)
      Should sample[0 : 1] ==# readfile(tempfile)
      call g:CSV.dump_file(g:expect_data[2], tempfile, 1)
      Should sample ==# readfile(tempfile)
    catch
      execute 'Should [0, ' . string(v:exception) . '][0]'
    finally
      if filereadable(tempfile)
        call delete(tempfile)
      endif
    endtry
  End
End
