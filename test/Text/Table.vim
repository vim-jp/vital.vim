scriptencoding utf-8

let s:suite = themis#suite('Text.Table')
let s:assert = themis#helper('assert')

function! s:suite.before() abort
    let s:T = vital#vital#new().import('Text.Table')
endfunction

function! s:suite.after() abort
    unlet! s:T
endfunction

function! s:suite.It_instantiates_a_new_object_without_configuration() abort
    let table = s:T.new()

    call s:assert.equals(table.hborder(), 1)
    call s:assert.equals(table.vborder(), 1)
    call s:assert.equals(table.border_style(), {})
    call s:assert.equals(table.columns(), [])
    call s:assert.equals(table.header(),  [])
    call s:assert.equals(table.rows(),    [])
    call s:assert.equals(table.footer(),  [])
endfunction

function! s:suite.It_instantiates_a_new_object_with_configuration() abort
    let table = s:T.new({
    \ 'hborder': 0,
    \ 'vborder': 0,
    \ 'border_style': {'joint': {'top': '^'}, 'border': {'bottom': '_'}},
    \ 'columns': [{}, {}, {}],
    \ 'header':  ['h1', 'h2', 'h3'],
    \ 'rows':    [['r1c1', 'r1c2', 'r1c3']],
    \ 'footer':  ['f1', 'f2', 'f3'],
    \})

    call s:assert.equals(table.hborder(), 0)
    call s:assert.equals(table.vborder(), 0)
    call s:assert.equals(table.border_style(), {'joint': {'top': '^'}, 'border': {'bottom': '_'}})
    call s:assert.equals(table.columns(), [{}, {}, {}])
    call s:assert.equals(table.header(),  ['h1', 'h2', 'h3'])
    call s:assert.equals(table.rows(),    [['r1c1', 'r1c2', 'r1c3']])
    call s:assert.equals(table.footer(),  ['f1', 'f2', 'f3'])
endfunction

function! s:suite.It_configures_properties() abort
    let table = s:T.new()

    call table.hborder(0)
    call table.vborder(0)
    call table.border_style({'joint': {'top': '^'}, 'border': {'bottom': '_'}})
    call table.columns([{}, {}, {}])
    call table.header(['h1', 'h2', 'h3'])
    call table.rows([['r1c1', 'r1c2', 'r1c3']])
    call table.footer(['f1', 'f2', 'f3'])

    call s:assert.equals(table.hborder(), 0)
    call s:assert.equals(table.vborder(), 0)
    call s:assert.equals(table.border_style(), {'joint': {'top': '^'}, 'border': {'bottom': '_'}})
    call s:assert.equals(table.columns(), [{}, {}, {}])
    call s:assert.equals(table.header(),  ['h1', 'h2', 'h3'])
    call s:assert.equals(table.rows(),    [['r1c1', 'r1c2', 'r1c3']])
    call s:assert.equals(table.footer(),  ['f1', 'f2', 'f3'])
endfunction

function! s:suite.It_throws_when_already_added_columns() abort
    let table = s:T.new()

    call table.columns([{}, {}, {}])
    call table.header(['h1', 'h2', 'h3'])
    call table.rows([['r1c1', 'r1c2', 'r1c3']])
    call table.footer(['f1', 'f2', 'f3'])

    Throws /^vital: Text\.Table:/ table.header(['h1', 'h2'])
    Throws /^vital: Text\.Table:/ table.rows([['r1c1', 'r1c2']])
    Throws /^vital: Text\.Table:/ table.footer(['f1', 'f2'])

    Throws /^vital: Text\.Table:/ table.columns([{}])
    Throws /^vital: Text\.Table:/ table.add_column({})
endfunction

function! s:suite.It_configures_properties_step_by_step() abort
    let table = s:T.new()

    call table.add_column({})
    call table.add_column({})
    call table.add_column({})

    call table.add_row(['r1c1', 'r1c2', 'r1c3'])

    call s:assert.equals(table.columns(), [{}, {}, {}])
    call s:assert.equals(table.rows(),    [['r1c1', 'r1c2', 'r1c3']])
endfunction

function! s:suite.It_makes_a_table() abort
    let table = s:T.new()

    call table.columns([{}, {}, {}])
    call table.header(['h1', 'h2', 'h3'])
    call table.rows([['r1c1', 'r1c2', 'r1c3']])
    call table.footer(['f1', 'f2', 'f3'])

    call s:assert.equals(table.stringify(), [
    \ '+------+------+------+',
    \ '| h1   | h2   | h3   |',
    \ '+------+------+------+',
    \ '| r1c1 | r1c2 | r1c3 |',
    \ '+------+------+------+',
    \ '| f1   | f2   | f3   |',
    \ '+------+------+------+',
    \])
endfunction

function! s:suite.It_makes_a_table_without_horizontal_border() abort
    let table = s:T.new()

    call table.hborder(0)
    call table.columns([{}, {}, {}])
    call table.header(['h1', 'h2', 'h3'])
    call table.rows([['r1c1', 'r1c2', 'r1c3']])
    call table.footer(['f1', 'f2', 'f3'])

    call s:assert.equals(table.stringify(), [
    \ '| h1   | h2   | h3   |',
    \ '| r1c1 | r1c2 | r1c3 |',
    \ '| f1   | f2   | f3   |',
    \])
endfunction

function! s:suite.It_makes_a_table_without_vertical_border() abort
    let table = s:T.new()

    call table.vborder(0)
    call table.columns([{}, {}, {}])
    call table.header(['h1', 'h2', 'h3'])
    call table.rows([['r1c1', 'r1c2', 'r1c3']])
    call table.footer(['f1', 'f2', 'f3'])

    call s:assert.equals(table.stringify(), [
    \ '----------------',
    \ ' h1   h2   h3   ',
    \ '----------------',
    \ ' r1c1 r1c2 r1c3 ',
    \ '----------------',
    \ ' f1   f2   f3   ',
    \ '----------------',
    \])
endfunction

function! s:suite.It_makes_a_table_without_horizontal_and_vertical_border() abort
    let table = s:T.new()

    call table.hborder(0)
    call table.vborder(0)
    call table.columns([{}, {}, {}])
    call table.header(['h1', 'h2', 'h3'])
    call table.rows([['r1c1', 'r1c2', 'r1c3']])
    call table.footer(['f1', 'f2', 'f3'])

    call s:assert.equals(table.stringify(), [
    \ 'h1   h2   h3  ',
    \ 'r1c1 r1c2 r1c3',
    \ 'f1   f2   f3  ',
    \])
endfunction

function! s:suite.It_makes_a_table_even_if_there_are_multibyte_characters() abort
    let table = s:T.new()

    call table.columns([{}, {}, {}])
    call table.header(['h1', 'h2', 'h3'])
    call table.rows([
    \ ['r1c1', 'r1c2', 'r1c3'],
    \ ['ああ', 'ああ', 'ああ'],
    \])
    call table.footer(['f1', 'f2', 'f3'])

    call s:assert.equals(table.stringify(), [
    \ '+------+------+------+',
    \ '| h1   | h2   | h3   |',
    \ '+------+------+------+',
    \ '| r1c1 | r1c2 | r1c3 |',
    \ '| ああ | ああ | ああ |',
    \ '+------+------+------+',
    \ '| f1   | f2   | f3   |',
    \ '+------+------+------+',
    \])
endfunction

function! s:suite.It_makes_a_table_which_wraps_each_cells() abort
    let table = s:T.new()

    call table.columns([{'width': 4}, {'width': 4}, {'width': 4}])
    call table.header(['h1', 'h2', 'h3'])
    call table.rows([
    \ ['r1c1', 'r1c2', 'r1c3'],
    \ ['あああ', 'あああ', 'あaあ'],
    \])
    call table.footer(['f1', 'f2', 'f3'])

    call s:assert.equals(table.stringify(), [
    \ '+------+------+------+',
    \ '| h1   | h2   | h3   |',
    \ '+------+------+------+',
    \ '| r1c1 | r1c2 | r1c3 |',
    \ '| ああ | ああ | あa  |',
    \ '| あ   | あ   | あ   |',
    \ '+------+------+------+',
    \ '| f1   | f2   | f3   |',
    \ '+------+------+------+',
    \])
endfunction

function! s:suite.It_makes_a_table_with_horizontal_and_vertical_alignment() abort
    let table = s:T.new()

    call table.columns([{'halign': 'right', 'valign': 'bottom', 'width': 4}, {'width': 4}, {'halign': 'center', 'valign': 'center', 'width': 4}])
    call table.header(['h1', 'h2', 'h3'])
    call table.rows([['r1c1', 'r1c2--------', 'r1c3']])
    call table.footer(['f1', 'f2', 'f3'])

    call s:assert.equals(table.stringify(), [
    \ '+------+------+------+',
    \ '|   h1 | h2   |  h3  |',
    \ '+------+------+------+',
    \ '|      | r1c2 |      |',
    \ '|      | ---- | r1c3 |',
    \ '| r1c1 | ---- |      |',
    \ '+------+------+------+',
    \ '|   f1 | f2   |  f3  |',
    \ '+------+------+------+',
    \])
endfunction

function! s:suite.It_makes_a_table_with_auto_wrapping_in_the_cell() abort
    let table = s:T.new()

    call table.columns([{'halign': 'right', 'valign': 'bottom', 'width': 4}, {'width': 4}, {'halign': 'center', 'valign': 'center', 'width': 4}])
    call table.header(['h1', 'h2', 'h3'])
    call table.rows([['r1c1', 'r1c2--------', 'r1c3']])
    call table.footer(['f1', 'f2', 'f3'])

    call s:assert.equals(table.stringify(), [
    \ '+------+------+------+',
    \ '|   h1 | h2   |  h3  |',
    \ '+------+------+------+',
    \ '|      | r1c2 |      |',
    \ '|      | ---- | r1c3 |',
    \ '| r1c1 | ---- |      |',
    \ '+------+------+------+',
    \ '|   f1 | f2   |  f3  |',
    \ '+------+------+------+',
    \])
endfunction

function! s:suite.It_make_a_table_only_header_and_footer() abort
    let table = s:T.new({
    \ 'columns': [{}, {}, {}],
    \ 'header':  ['header1', 'header2', 'header3'],
    \ 'footer':  ['footer1', 'footer2', 'footer3'],
    \})

    call s:assert.equals(table.stringify(), [
    \ '+---------+---------+---------+',
    \ '| header1 | header2 | header3 |',
    \ '+---------+---------+---------+',
    \ '+---------+---------+---------+',
    \ '| footer1 | footer2 | footer3 |',
    \ '+---------+---------+---------+',
    \])
endfunction

function! s:suite.It_has_initial_header_and_footer_and_rows_later() abort
    let table = s:T.new({
    \ 'columns': [{}, {}, {}],
    \ 'header':  ['header1', 'header2', 'header3'],
    \ 'footer':  ['footer1', 'footer2', 'footer3'],
    \})

    call table.rows([
    \ ['r1c1', 'r1c2', 'r1c3'],
    \ ['r2c1', 'r2c2', 'r2c3'],
    \ ['r3c1', 'r3c2', 'r3c3'],
    \])

    call s:assert.equals(table.stringify(), [
    \ '+---------+---------+---------+',
    \ '| header1 | header2 | header3 |',
    \ '+---------+---------+---------+',
    \ '| r1c1    | r1c2    | r1c3    |',
    \ '| r2c1    | r2c2    | r2c3    |',
    \ '| r3c1    | r3c2    | r3c3    |',
    \ '+---------+---------+---------+',
    \ '| footer1 | footer2 | footer3 |',
    \ '+---------+---------+---------+',
    \])
endfunction

function! s:suite.It_has_no_header_and_footer() abort
    let table = s:T.new({
    \ 'columns': [{}, {}, {}],
    \})

    call table.rows([
    \ ['r1c1', 'r1c2', 'r1c3'],
    \ ['r2c1', 'r2c2', 'r2c3'],
    \ ['r3c1', 'r3c2', 'r3c3'],
    \])

    call s:assert.equals(table.stringify(), [
    \ '+------+------+------+',
    \ '| r1c1 | r1c2 | r1c3 |',
    \ '| r2c1 | r2c2 | r2c3 |',
    \ '| r3c1 | r3c2 | r3c3 |',
    \ '+------+------+------+',
    \])
endfunction

function! s:suite.It_lays_out_by_cell_style_and_column_style() abort
    let table = s:T.new({
    \ 'columns': [{'halign': 'center', 'valign': 'center', 'width': 10}],
    \})

    call table.header([{'text': 0, 'style': {'halign': 'right'}}])
    call table.footer([{'text': 0, 'style': {'halign': 'right'}}])
    call table.rows([
    \ [{'text': 'r1c1'}],
    \ [{'text': 'r2c1', 'style': {'halign': 'left'}}],
    \ [{'text': 'r3c1', 'style': {'halign': 'right'}}],
    \])

    call s:assert.equals(table.stringify(), [
    \ '+------------+',
    \ '|          0 |',
    \ '+------------+',
    \ '|    r1c1    |',
    \ '| r2c1       |',
    \ '|       r3c1 |',
    \ '+------------+',
    \ '|          0 |',
    \ '+------------+',
    \])
endfunction

function! s:suite.It_automatically_resizes_width_for_each_column() abort
    let table = s:T.new({
    \ 'columns': [{'width': 5}, {'max_width': 10}, {'min_width': 3}],
    \})

    call table.header(['', '', ''])
    call table.footer(['', '', ''])
    call table.rows([
    \ ['', 'あいうえをかきくけ', ''],
    \])

    call s:assert.equals(table.stringify(), [
    \ '+-------+------------+-----+',
    \ '|       |            |     |',
    \ '+-------+------------+-----+',
    \ '|       | あいうえを |     |',
    \ '|       | かきくけ   |     |',
    \ '+-------+------------+-----+',
    \ '|       |            |     |',
    \ '+-------+------------+-----+',
    \])
endfunction

function! s:suite.It_suppresses_resizes_if_specified_table_style() abort
    let table = s:T.new({
    \ 'columns': [{'width': 5}, {'width': 10}, {'max_width': 30}],
    \})

    call table.rows([
    \ ['', '', ''],
    \])

    call s:assert.equals(table.stringify({'max_width': 40}), [
    \ '+-------+------------+-----------------+',
    \ '|       |            |                 |',
    \ '+-------+------------+-----------------+',
    \])
endfunction

function! s:suite.It_can_changes_joints_and_borders() abort
    let table = s:T.new({
    \ 'columns': [{'min_width': 5}, {'min_width': 5}, {'min_width': 5}],
    \})

    call table.border_style({
    \ 'joint': {
    \   'top_left': 'tl',
    \   'top': '*',
    \   'top_right': 'tr',
    \   'head_left': '<',
    \   'head': '+*+',
    \   'head_right': '>',
    \   'left': '<<<<',
    \   'row': '+',
    \   'right': '>>>>',
    \   'foot_left': '<',
    \   'foot': '+*+',
    \   'foot_right': '>',
    \   'bottom_left': 'bl',
    \   'bottom': '*',
    \   'bottom_right': 'br',
    \ },
    \ 'border': {
    \   'top': 'tt',
    \   'head': '^',
    \   'row': 'rr',
    \   'column': '///',
    \   'left': '<<',
    \   'right': '>>',
    \   'foot': 'v',
    \   'bottom': 'bb',
    \ },
    \})
    call table.header(['', '', ''])
    call table.rows([
    \ ['', '', ''],
    \ ['', '', ''],
    \])
    call table.footer(['', '', ''])

    call s:assert.equals(table.stringify(), [
    \ 'tltttttttt*tttttttttt*tttttttttr',
    \ '<<       ///        ///       >>',
    \ '<^^^^^^^^+*+^^^^^^^^+*+^^^^^^^^>',
    \ '<<       ///        ///       >>',
    \ '<<<<rrrrrr+rrrrrrrrrr+rrrrrr>>>>',
    \ '<<       ///        ///       >>',
    \ '<vvvvvvvv+*+vvvvvvvv+*+vvvvvvvv>',
    \ '<<       ///        ///       >>',
    \ 'blbbbbbbbb*bbbbbbbbbb*bbbbbbbbbr',
    \])
endfunction

function! s:suite.It_can_use_for_sudden_death() abort
    let table = s:T.new({
    \ 'columns': [{}],
    \})

    call table.border_style({
    \ 'joint': {
    \   'top_left':     '＿',
    \   'top_right':    '＿',
    \   'bottom_left':  '￣Y',
    \   'bottom_right': '￣',
    \ },
    \ 'border': {
    \   'top':    '人',
    \   'left':   '＞',
    \   'right':  '＜',
    \   'bottom': '^Y',
    \ },
    \})
    call table.rows([
    \ ['突然の死'],
    \])

    call s:assert.equals(table.stringify(), [
    \ '＿人人人人人＿',
    \ '＞ 突然の死 ＜',
    \ '￣Y^Y^Y^Y^Y ￣',
    \])
endfunction
