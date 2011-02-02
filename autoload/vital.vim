function! vital#of(version)
  return vital#_{a:version}#new()
endfunction

let s:sfile = expand('<sfile>')
function! vital#{fnamemodify(s:sfile, ':h:h:t')}()
  let vitaldir = fnamemodify(s:sfile, ':h') . '/vital/'
  let vitals = split(glob(vitaldir . '*.vim'), "\n")
  if len(vitals) != 1
    echoerr "too many files in " . vitaldir
    return
  else
    return vital#{fnamemodify(vitals[0], ':t:r')}#new()
  end
endfunction


