function! vital#of(version)
  return vital#_{a:version}#new()
endfunction

function! vital#latest(sfile)
  let vitaldir = fnamemodify(a:sfile, ':h') . '/vital/'
  let vitals = split(glob(vitaldir . '*.vim'), "\n")
  if len(vitals) != 1
    echoerr vitals
    echoerr "too many files in " . vitaldir
    return
  else
    return vital#{fnamemodify(vitals[0], ':t:r')}#new()
  end
endfunction


