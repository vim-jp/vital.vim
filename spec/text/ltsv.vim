source spec/base.vim

let g:LTSV = vital#of('vital').import('Text.Ltsv')
let g:sample_file = expand('<sfile>:p:h') . '/ltsv-sample.txt'
let g:expect_data = [
\   {'name': 'Web.Http', 'maintainer': 'mattn'},
\   {'name': 'Text.Ltsv', 'maintainer': 'thinca'},
\   {'name': 'Text.Lexer', 'maintainer': 'rbtnn'},
\ ]

Context Text.Ltsv.parse()
  It parses records of LTSV
    let ltsv_data = join(readfile(g:sample_file), "\n")
    Should g:expect_data == g:LTSV.parse(ltsv_data)
  End
End

Context Text.Ltsv.parse_record()
  It parses an LTSV file
    let ltsv_record = readfile(g:sample_file, 0, 1)[0]
    let expect_record = {'name': 'Web.Http', 'maintainer': 'mattn'}
    Should expect_record == g:LTSV.parse_record(ltsv_record)
  End
  It throws an exception when invalid data was passed
    try
      call g:LTSV.parse_record("hoge:huga\thehehe")  " colon missed
      Should 0
    catch /^vital: Text\.Ltsv:/
      Should 1
    endtry
    try
      call g:LTSV.parse_record("hoge:huga\tfoo/bar:hey")  " invalid label
      Should 0
    catch /^vital: Text\.Ltsv:/
      Should 1
    endtry
  End
End

Context Text.Ltsv.parse_file()
  It parses an LTSV file
    Should g:expect_data == g:LTSV.parse_file(g:sample_file)
  End
End

Context Text.Ltsv.dump()
  It convets a list objects to a LTSV string
    Should join(readfile(g:sample_file), "\n") ==# g:LTSV.dump(g:expect_data)
  End
  It convets an object to a LTSV string
    Should readfile(g:sample_file)[0] ==# g:LTSV.dump(g:expect_data[0])
  End
End

Context Text.Ltsv.dump_file()
  It dumps the data to a file
    let tempfile = tempname()
    try
      call g:LTSV.dump_file(g:expect_data, tempfile)
      Should readfile(g:sample_file) == readfile(tempfile)
    catch
      Should 0
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
      call g:LTSV.dump_file(g:expect_data[0], tempfile)
      Should sample[0 : 0] == readfile(tempfile)
      call g:LTSV.dump_file(g:expect_data[1], tempfile, 1)
      Should sample[0 : 1] == readfile(tempfile)
      call g:LTSV.dump_file(g:expect_data[2], tempfile, 1)
      Should sample == readfile(tempfile)
    catch
      Should 0
    finally
      if filereadable(tempfile)
        call delete(tempfile)
      endif
    endtry
  End
End
