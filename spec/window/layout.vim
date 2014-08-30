source spec/base.vim

let g:WL = vital#of('vital').import('Window.Layout')

Context Window.Layout
  It lays out a current tabpage and gets winnr for each window.
    tabnew
    tabonly
    let buffers = [
    \ {'id': 'hoge', 'bufname': 'HOGE'},
    \ {'id': 'fuga', 'bufname': 'FUGA'},
    \ {'id': 'piyo', 'bufname': 'PIYO'},
    \]
    let layout_data = {
    \ 'layout': 'border',
    \ 'north':  {'bufref': 'hoge', 'height': 0.5, 'walias': 'one'},
    \ 'center': {'bufref': 'fuga', 'width': 100, 'walias': 'two'},
    \ 'east':   {
    \   'layout': 'border',
    \   'north':  {'bufref': 'piyo', 'height': 0.333, 'walias': 'three'},
    \   'center': {'bufref': 'piyo', 'height': 0.333, 'walias': 'four'},
    \   'south':  {'bufref': 'piyo', 'height': 0.333, 'walias': 'five'},
    \ },
    \}

    let expects_tabnr = tabpagenr()

    let layout = g:WL.new()

    call layout.apply(buffers, layout_data)

    Should tabpagenr() == expects_tabnr
    Should winnr('$') == 5
    Should layout.winnr('one') == 1
    Should layout.winnr('two') == 2
    Should layout.winnr('three') == 3
    Should layout.winnr('four') == 4
    Should layout.winnr('five') == 5
  End

  It uses a own buffer.
    tabnew
    tabonly
    new
    only
    let buffers = [
    \ {'id': 'hoge', 'bufnr': bufnr('#')},
    \]
    let layout_data = {
    \ 'layout': 'border',
    \ 'north':  {'bufref': 'hoge', 'walias': 'one'},
    \ 'center': {'bufref': 'hoge', 'walias': 'two'},
    \}

    let expects_bufnr = bufnr('#')

    let layout = g:WL.new()

    call layout.apply(buffers, layout_data)

    let nr = layout.winnr('one')
    execute nr 'wincmd w'
    Should bufnr('%') == expects_bufnr

    let nr = layout.winnr('two')
    execute nr 'wincmd w'
    Should bufnr('%') == expects_bufnr
  End

  It initialize a buffer by funcref.
    let g:ncalls = 0

    function! Initializer()
        Should bufname('%') ==# 'RIDER 1st'
        let g:ncalls += 1
    endfunction

    tabnew
    tabonly
    let buffers = [
    \ {'id': 'hoge', 'bufname': 'RIDER 1st', 'initializer': function('Initializer')},
    \]
    let layout_data = {
    \ 'layout': 'border',
    \ 'north':  {'bufref': 'hoge'},
    \ 'center': {'bufref': 'hoge'},
    \}

    let layout = g:WL.new()

    call layout.apply(buffers, layout_data)

    Should g:ncalls == 1
    unlet g:ncalls
  End

  It initialize a buffer by dictionary funcref.
    let g:ncalls = 0

    let initializer = {}
    function! initializer.pupu()
        Should bufname('%') ==# 'RIDER 2nd'
        let g:ncalls += 1
    endfunction

    tabnew
    tabonly
    let buffers = [
    \ {'id': 'hoge', 'bufname': 'RIDER 2nd', 'initializer': [initializer.pupu, initializer]},
    \]
    let layout_data = {
    \ 'layout': 'border',
    \ 'north':  {'bufref': 'hoge'},
    \ 'center': {'bufref': 'hoge'},
    \}

    let layout = g:WL.new()

    call layout.apply(buffers, layout_data)

    Should g:ncalls == 1
    unlet g:ncalls
  End
End
