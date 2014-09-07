source spec/base.vim

let g:CSV = vital#of('vital').import('Text.CSV')
let g:sample_file_in = expand('<sfile>:p:h') . '/csv-sample-in.txt'
let g:sample_file_out = expand('<sfile>:p:h') . '/csv-sample-out.txt'
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
    let csv_data = join(readfile(g:sample_file_in), "\n")
    Should g:expect_data ==# g:CSV.parse(csv_data)
  End
End

Context Text.CSV.parse_record()
  It parses an CSV file
    let csv_record = readfile(g:sample_file_in, 0, 1)[0]
    let expect_record = ['foo', 'bar']
    Should [expect_record ==# g:CSV.parse_record(csv_record), ][0]
  End
  It throws an exception when invalid data was passed
    " unclosed double-quote.
    ShouldThrow g:CSV.parse_record('"foo'), /.*/

    " The line which has double-quote(s) or comma(s)
    " must be wrapped by double-quotes.
    ShouldThrow g:CSV.parse_record('foo"bar'), /.*/
  End
End

Context Text.CSV.parse_file()
  It parses an CSV file
    Should g:expect_data ==# g:CSV.parse_file(g:sample_file_in)
  End
End

Context Text.CSV.dump()
  It converts a list objects to a CSV string
    let out_string = join(readfile(g:sample_file_out), "\n")
    Should out_string ==# g:CSV.dump(g:expect_data)
  End
  It converts an object to a CSV string
    ShouldThrow g:CSV.dump('string')
    ShouldThrow g:CSV.dump(0)
    ShouldThrow g:CSV.dump({'dummy': 1})
  End
End

Context Text.CSV.dump_file()
  It dumps the data to a file
    let tempfile = tempname()
    try
      call g:CSV.dump_file(g:expect_data, tempfile)
      Should readfile(g:sample_file_out) ==# readfile(tempfile)
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
      let out_lines = readfile(g:sample_file_out)

      " 1st line, 1-2 lines, 1-1 lines, ...
      for i in range(len(g:expect_data))
        call g:CSV.dump_file([g:expect_data[i]], tempfile, 1)
        Should out_lines[0 : i] ==# readfile(tempfile)
      endfor
    catch
      execute 'Should [0, ' . string(v:exception) . '][0]'
    finally
      if filereadable(tempfile)
        call delete(tempfile)
      endif
    endtry
  End
End
