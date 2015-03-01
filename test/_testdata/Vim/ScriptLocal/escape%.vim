function s:SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun

let g:vital_test_Vim_ScriptLocal_escape_SID = s:SID()

