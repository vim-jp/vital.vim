" HMAC: Keyed-Hashing for Message Authentication
" RFC 2104 https://tools.ietf.org/html/rfc2104

function! s:_vital_loaded(V) abort
  let s:V = a:V

  let s:List = s:V.import('Data.List')
  let s:bitwise = s:V.import('Bitwise')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise', 'Data.List']
endfunction

let s:HMAC = {
      \   '__type__': 'HMAC',
      \   '_dict': {
      \     'hash':v:null,
      \     'key' :v:null,
      \   }
      \ }

" s:new() creates a new instance of HMAC object.
" @param {hash object},{key string|bytes list}
function! s:new(...) abort
  if a:0 > 2
    call s:_throw(printf('.new() expected at most 2 arguments, got %d', a:0))
  endif
  let hmac = deepcopy(s:HMAC)
  if a:0 is# 1
    call call(hmac.hash, [a:1], hmac)
  elseif a:0 is# 2
    call call(hmac.hash, [a:1], hmac)
    call call(hmac.key,  [a:2], hmac)
  endif
  return hmac
endfunction

function! s:HMAC.key(key) abort
  if type(a:key) is# type([])
    let self._dict['key'] = a:key
  elseif type(a:key) is# type('')
    let self._dict['key'] = s:_str2bytes(a:key)
  else
    call s:_throw('given argument is not key data')
  endif
endfunction

function! s:HMAC.hash(hashobj) abort
  if type(a:hashobj) is# type({})
        \ && has_key(a:hashobj,'digest_raw')
        \ && type(a:hashobj.digest_raw) is# type(function('tr'))
    let self._dict['hash'] = a:hashobj
  else
    call s:_throw('given argument is not HASH API object')
  endif
endfunction

function! s:HMAC.calc(data) abort
  if type(a:data) is# type([])
    let data = a:data
  elseif type(a:data) is# type('')
    let data = s:_str2bytes(a:data)
  else
    call s:_throw('given argument is not valid data')
  endif

  let key  = self._dict['key']
  let hash = self._dict['hash']

  if (type(key) isnot# type([])) || (type(hash) isnot# type({}))
    call s:_throw('setup invalid key or hashobj')
  endif

  if len(key) > 64
    let key = hash.digest_raw(key)
  endif

  let ipad = s:List.new(64, {-> 0})
  let opad = s:List.new(64, {-> 0})

  for i in range(len(key))
    let ipad[i] = key[i]
    let opad[i] = key[i]
  endfor

  for i in range(64)
    let ipad[i] = s:bitwise.xor(ipad[i],0x36)
    let opad[i] = s:bitwise.xor(opad[i],0x5c)
  endfor

  let digest = hash.digest_raw(ipad + data)
  let digest = hash.digest_raw(opad + digest)

  return digest
endfunction

function! s:HMAC.hmac(data) abort
  return s:_bytes2str(self.calc(a:data))
endfunction

function! s:_str2bytes(str) abort
  return map(range(len(a:str)), 'char2nr(a:str[v:val])')
endfunction

function! s:_bytes2str(bytes) abort
  return join(map(a:bytes, 'printf(''%02x'', v:val)'), '')
endfunction

function! s:_throw(message) abort
  throw 'vital: Hash.HMAC: ' . a:message
endfunction
