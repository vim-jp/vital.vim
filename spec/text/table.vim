source spec/base.vim

let g:T = vital#of('vital').import('Text.Table')

Context Text.Table.new()
  It instantiates a new object without configuration
    let table = g:T.new()

    Should table.hborder() == 1
    Should table.vborder() == 1
    Should table.columns() == []
    Should table.header()  == []
    Should table.rows()    == []
    Should table.footer()  == []
  End

  It instantiates a new object with configuration
    let table = g:T.new({
    \ 'hborder': 0,
    \ 'vborder': 0,
    \ 'columns': [{}, {}, {}],
    \ 'header':  ['h1', 'h2', 'h3'],
    \ 'rows':    [['r1c1', 'r1c2', 'r1c3']],
    \ 'footer':  ['f1', 'f2', 'f3'],
    \})

    Should table.hborder() == 0
    Should table.vborder() == 0
    Should table.columns() == [{}, {}, {}]
    Should table.header()  == ['h1', 'h2', 'h3']
    Should table.rows()    == [['r1c1', 'r1c2', 'r1c3']]
    Should table.footer()  == ['f1', 'f2', 'f3']
  End

  It configures properties
    let table = g:T.new()

    call table.hborder(0)
    call table.vborder(0)
    call table.columns([{}, {}, {}])
    call table.header(['h1', 'h2', 'h3'])
    call table.rows([['r1c1', 'r1c2', 'r1c3']])
    call table.footer(['f1', 'f2', 'f3'])

    Should table.hborder() == 0
    Should table.vborder() == 0
    Should table.columns() == [{}, {}, {}]
    Should table.header()  == ['h1', 'h2', 'h3']
    Should table.rows()    == [['r1c1', 'r1c2', 'r1c3']]
    Should table.footer()  == ['f1', 'f2', 'f3']
  End

  It throws when already added columns
    let table = g:T.new()

    call table.columns([{}, {}, {}])
    call table.header(['h1', 'h2', 'h3'])
    call table.rows([['r1c1', 'r1c2', 'r1c3']])
    call table.footer(['f1', 'f2', 'f3'])

    ShouldThrow table.header(['h1', 'h2'])
    ShouldThrow table.rows([['r1c1', 'r1c2']])
    ShouldThrow table.footer(['f1', 'f2'])

    ShouldThrow table.columns([{}])
    ShouldThrow table.add_column({})
  End

  It configures properties step by step
    let table = g:T.new()

    call table.add_column({})
    call table.add_column({})
    call table.add_column({})

    call table.add_row(['r1c1', 'r1c2', 'r1c3'])

    Should table.columns() == [{}, {}, {}]
    Should table.rows()    == [['r1c1', 'r1c2', 'r1c3']]
  End

  It makes a table
    let table = g:T.new()

    call table.columns([{}, {}, {}])
    call table.header(['h1', 'h2', 'h3'])
    call table.rows([['r1c1', 'r1c2', 'r1c3']])
    call table.footer(['f1', 'f2', 'f3'])

    Should table.stringify() == [
    \ '+------+------+------+',
    \ '| h1   | h2   | h3   |',
    \ '+------+------+------+',
    \ '| r1c1 | r1c2 | r1c3 |',
    \ '+------+------+------+',
    \ '| f1   | f2   | f3   |',
    \ '+------+------+------+',
    \]
  End

  It makes a table without horizontal border
    let table = g:T.new()

    call table.hborder(0)
    call table.columns([{}, {}, {}])
    call table.header(['h1', 'h2', 'h3'])
    call table.rows([['r1c1', 'r1c2', 'r1c3']])
    call table.footer(['f1', 'f2', 'f3'])

    Should table.stringify() == [
    \ '| h1   | h2   | h3   |',
    \ '| r1c1 | r1c2 | r1c3 |',
    \ '| f1   | f2   | f3   |',
    \]
  End

  It makes a table without vertical border
    let table = g:T.new()

    call table.vborder(0)
    call table.columns([{}, {}, {}])
    call table.header(['h1', 'h2', 'h3'])
    call table.rows([['r1c1', 'r1c2', 'r1c3']])
    call table.footer(['f1', 'f2', 'f3'])

    Should table.stringify() == [
    \ '----------------',
    \ ' h1   h2   h3   ',
    \ '----------------',
    \ ' r1c1 r1c2 r1c3 ',
    \ '----------------',
    \ ' f1   f2   f3   ',
    \ '----------------',
    \]
  End

  It makes a table without horizontal and vertical border
    let table = g:T.new()

    call table.hborder(0)
    call table.vborder(0)
    call table.columns([{}, {}, {}])
    call table.header(['h1', 'h2', 'h3'])
    call table.rows([['r1c1', 'r1c2', 'r1c3']])
    call table.footer(['f1', 'f2', 'f3'])

    Should table.stringify() == [
    \ 'h1   h2   h3  ',
    \ 'r1c1 r1c2 r1c3',
    \ 'f1   f2   f3  ',
    \]
  End

  It makes a table even if there are multi-byte characters
    let table = g:T.new()

    call table.columns([{}, {}, {}])
    call table.header(['h1', 'h2', 'h3'])
    call table.rows([
    \ ['r1c1', 'r1c2', 'r1c3'],
    \ ['ああ', 'ああ', 'ああ'],
    \])
    call table.footer(['f1', 'f2', 'f3'])

    Should table.stringify() == [
    \ '+------+------+------+',
    \ '| h1   | h2   | h3   |',
    \ '+------+------+------+',
    \ '| r1c1 | r1c2 | r1c3 |',
    \ '| ああ | ああ | ああ |',
    \ '+------+------+------+',
    \ '| f1   | f2   | f3   |',
    \ '+------+------+------+',
    \]
  End

  It makes a table which wraps each cells
    let table = g:T.new()

    call table.columns([{'width': 4}, {'width': 4}, {'width': 4}])
    call table.header(['h1', 'h2', 'h3'])
    call table.rows([
    \ ['r1c1', 'r1c2', 'r1c3'],
    \ ['あああ', 'あああ', 'あaあ'],
    \])
    call table.footer(['f1', 'f2', 'f3'])

    Should table.stringify() == [
    \ '+------+------+------+',
    \ '| h1   | h2   | h3   |',
    \ '+------+------+------+',
    \ '| r1c1 | r1c2 | r1c3 |',
    \ '| ああ | ああ | あa  |',
    \ '| あ   | あ   | あ   |',
    \ '+------+------+------+',
    \ '| f1   | f2   | f3   |',
    \ '+------+------+------+',
    \]
  End

  It makes a table with horizontal and vertical alignment
    let table = g:T.new()

    call table.columns([{'halign': 'right', 'valign': 'bottom', 'width': 4}, {'width': 4}, {'halign': 'center', 'valign': 'center', 'width': 4}])
    call table.header(['h1', 'h2', 'h3'])
    call table.rows([['r1c1', 'r1c2--------', 'r1c3']])
    call table.footer(['f1', 'f2', 'f3'])

    Should table.stringify() == [
    \ '+------+------+------+',
    \ '|   h1 | h2   |  h3  |',
    \ '+------+------+------+',
    \ '|      | r1c2 |      |',
    \ '|      | ---- | r1c3 |',
    \ '| r1c1 | ---- |      |',
    \ '+------+------+------+',
    \ '|   f1 | f2   |  f3  |',
    \ '+------+------+------+',
    \]
  End

  It makes a table with auto wrapping in the cell
    let table = g:T.new()

    call table.columns([{'halign': 'right', 'valign': 'bottom', 'width': 4}, {'width': 4}, {'halign': 'center', 'valign': 'center', 'width': 4}])
    call table.header(['h1', 'h2', 'h3'])
    call table.rows([['r1c1', 'r1c2--------', 'r1c3']])
    call table.footer(['f1', 'f2', 'f3'])

    Should table.stringify() == [
    \ '+------+------+------+',
    \ '|   h1 | h2   |  h3  |',
    \ '+------+------+------+',
    \ '|      | r1c2 |      |',
    \ '|      | ---- | r1c3 |',
    \ '| r1c1 | ---- |      |',
    \ '+------+------+------+',
    \ '|   f1 | f2   |  f3  |',
    \ '+------+------+------+',
    \]
  End

  It make a table only header and footer
    let table = g:T.new({
    \ 'columns': [{}, {}, {}],
    \ 'header':  ['header1', 'header2', 'header3'],
    \ 'footer':  ['footer1', 'footer2', 'footer3'],
    \})

    Should table.stringify() == [
    \ '+---------+---------+---------+',
    \ '| header1 | header2 | header3 |',
    \ '+---------+---------+---------+',
    \ '+---------+---------+---------+',
    \ '| footer1 | footer2 | footer3 |',
    \ '+---------+---------+---------+',
    \]
  End

  It has initial header and footer, and rows later
    let table = g:T.new({
    \ 'columns': [{}, {}, {}],
    \ 'header':  ['header1', 'header2', 'header3'],
    \ 'footer':  ['footer1', 'footer2', 'footer3'],
    \})

    call table.rows([
    \ ['r1c1', 'r1c2', 'r1c3'],
    \ ['r2c1', 'r2c2', 'r2c3'],
    \ ['r3c1', 'r3c2', 'r3c3'],
    \])

    Should table.stringify() == [
    \ '+---------+---------+---------+',
    \ '| header1 | header2 | header3 |',
    \ '+---------+---------+---------+',
    \ '| r1c1    | r1c2    | r1c3    |',
    \ '| r2c1    | r2c2    | r2c3    |',
    \ '| r3c1    | r3c2    | r3c3    |',
    \ '+---------+---------+---------+',
    \ '| footer1 | footer2 | footer3 |',
    \ '+---------+---------+---------+',
    \]
  End

  It has no header and footer
    let table = g:T.new({
    \ 'columns': [{}, {}, {}],
    \})

    call table.rows([
    \ ['r1c1', 'r1c2', 'r1c3'],
    \ ['r2c1', 'r2c2', 'r2c3'],
    \ ['r3c1', 'r3c2', 'r3c3'],
    \])

    Should table.stringify() == [
    \ '+------+------+------+',
    \ '| r1c1 | r1c2 | r1c3 |',
    \ '| r2c1 | r2c2 | r2c3 |',
    \ '| r3c1 | r3c2 | r3c3 |',
    \ '+------+------+------+',
    \]
  End

  It lays out by cell style and column style
    let table = g:T.new({
    \ 'columns': [{'halign': 'center', 'valign': 'center', 'width': 10}],
    \})

    call table.header([{'text': 0, 'style': {'halign': 'right'}}])
    call table.footer([{'text': 0, 'style': {'halign': 'right'}}])
    call table.rows([
    \ [{'text': 'r1c1'}],
    \ [{'text': 'r2c1', 'style': {'halign': 'left'}}],
    \ [{'text': 'r3c1', 'style': {'halign': 'right'}}],
    \])

    Should table.stringify() == [
    \ '+------------+',
    \ '|          0 |',
    \ '+------------+',
    \ '|    r1c1    |',
    \ '| r2c1       |',
    \ '|       r3c1 |',
    \ '+------------+',
    \ '|          0 |',
    \ '+------------+',
    \]
  End

  It automatically resizes width for each column
    let table = g:T.new({
    \ 'columns': [{'width': 5}, {'max_width': 10}, {'min_width': 3}],
    \})

    call table.header(['', '', ''])
    call table.footer(['', '', ''])
    call table.rows([
    \ ['', 'あいうえをかきくけ', ''],
    \])

    Should table.stringify() == [
    \ '+-------+------------+-----+',
    \ '|       |            |     |',
    \ '+-------+------------+-----+',
    \ '|       | あいうえを |     |',
    \ '|       | かきくけ   |     |',
    \ '+-------+------------+-----+',
    \ '|       |            |     |',
    \ '+-------+------------+-----+',
    \]
  End

  It supresses resizes if specified table style
    let table = g:T.new({
    \ 'columns': [{'width': 5}, {'width': 10}, {'max_width': 30}],
    \})

    call table.rows([
    \ ['', '', ''],
    \])

    Should table.stringify({'max_width': 40}) == [
    \ '+-------+------------+-----------------+',
    \ '|       |            |                 |',
    \ '+-------+------------+-----------------+',
    \]
  End
End
