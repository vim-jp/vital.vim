source spec/base.vim

let g:T = vital#of('vital').import('Vim.ViewTracer')

function! s:clear_tab_and_windows()
  tabnew
  tabonly!
endfunction

Context Vim.ViewTracer.find()
  It gets current tabnr and winnr of handle
    call s:clear_tab_and_windows()
    let handle = T.trace_window()
    Should T.find(handle) == [1, 1]
    leftabove new
    Should T.find(handle) == [1, 2]
    tabnew
    tabmove 0
    Should T.find(handle) == [2, 2]
    call s:clear_tab_and_windows()
    Should T.find(handle) == [0, 0]
  End
  It gets current tabnr of handle
    call s:clear_tab_and_windows()
    let handle = T.trace_tabpage()
    Should T.find(handle) == [1, 0]
    tabnew
    tabmove 0
    Should T.find(handle) == [2, 0]
    tabnew
    Should T.find(handle) == [3, 0]
    call s:clear_tab_and_windows()
    Should T.find(handle) == [0, 0]
  End
End

Context Vim.ViewTracer.exists()
  It checks whether window of handle exists
    call s:clear_tab_and_windows()
    let handle = T.trace_window()
    Should T.exists(handle)
    call s:clear_tab_and_windows()
    Should !T.exists(handle)
  End
  It checks whether tabpage of handle exists
    call s:clear_tab_and_windows()
    let handle = T.trace_tabpage()
    Should T.exists(handle)
    call s:clear_tab_and_windows()
    Should !T.exists(handle)
  End
End

Context Vim.ViewTracer.tabnr()
  It gets current tabnr of handle
    call s:clear_tab_and_windows()
    let handle = T.trace_tabpage()
    Should T.tabnr(handle) == 1
    tabnew
    tabmove 0
    Should T.tabnr(handle) == 2
    tabnew
    Should T.tabnr(handle) == 3
    call s:clear_tab_and_windows()
    Should T.tabnr(handle) == 0
  End
End

Context Vim.ViewTracer.winnr()
  It gets current winnr of handle
    call s:clear_tab_and_windows()
    let handle = T.trace_window()
    Should T.winnr(handle) == 1
    leftabove new
    Should T.winnr(handle) == 2
    tabnew
    tabmove 0
    Should T.winnr(handle) == 2
    call s:clear_tab_and_windows()
    Should T.winnr(handle) == 0
  End
End

Context Vim.ViewTracer.jump()
  It jumps to window of handle
    call s:clear_tab_and_windows()
    let handle = T.trace_window()
    rightbelow new
    Should [tabpagenr(), winnr()] == [1, 2]
    call T.jump(handle)
    Should [tabpagenr(), winnr()] == [1, 1]
    tabnew
    tabmove 0
    Should [tabpagenr(), winnr()] == [1, 1]
    call T.jump(handle)
    Should [tabpagenr(), winnr()] == [2, 1]
  End
  It gets current tabnr of handle
    call s:clear_tab_and_windows()
    let handle = T.trace_tabpage()
    tabnew
    tabmove 0
    Should tabpagenr() == 1
    call T.jump(handle)
    Should tabpagenr() == 2
    tabnew
    Should tabpagenr() == 3
    call T.jump(handle)
    Should tabpagenr() == 2
  End
End

