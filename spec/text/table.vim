source spec/base.vim

let g:T= vital#of('vital').import('Text.Table')

Context Text.Table.new()
  It instantiates a new object without configuration
    let table= g:T.new()

    Should table.hborder() == 1
    Should table.vborder() == 1
    Should table.columns() == []
    Should table.header()  == []
    Should table.rows()    == []
    Should table.footer()  == []
  End

  It instantiates a new object with configuration
    let table= g:T.new({
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
    let table= g:T.new()

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

  It remove previous state
    let table= g:T.new()

    call table.columns([{}, {}, {}])
    call table.header(['h1', 'h2', 'h3'])
    call table.rows([['r1c1', 'r1c2', 'r1c3']])
    call table.footer(['f1', 'f2', 'f3'])

    Should table.columns() == [{}, {}, {}]
    Should table.header()  == ['h1', 'h2', 'h3']
    Should table.rows()    == [['r1c1', 'r1c2', 'r1c3']]
    Should table.footer()  == ['f1', 'f2', 'f3']

    call table.columns([{}, {}])
    call table.header(['h1', 'h2'])
    call table.rows([['r1c1', 'r1c2']])
    call table.footer(['f1', 'f2'])

    Should table.columns() == [{}, {}]
    Should table.header()  == ['h1', 'h2']
    Should table.rows()    == [['r1c1', 'r1c2']]
    Should table.footer()  == ['f1', 'f2']
  End

  It configures properties step by step
    let table= g:T.new()

    call table.add_column({})
    call table.add_column({})
    call table.add_column({})

    call table.add_row(['r1c1', 'r1c2', 'r1c3'])

    Should table.columns() == [{}, {}, {}]
    Should table.rows()    == [['r1c1', 'r1c2', 'r1c3']]
  End

  It makes a table
    let table= g:T.new()

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
    let table= g:T.new()

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
    let table= g:T.new()

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
    let table= g:T.new()

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
    let table= g:T.new()

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
    let table= g:T.new()

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
    let table= g:T.new()

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
    let table= g:T.new()

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
End
