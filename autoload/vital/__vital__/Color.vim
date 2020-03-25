" RGB/HSL conversion library

let s:save_cpo = &cpo
set cpo&vim


let s:Color = {}

function! s:Color.as_rgb_str() abort
  let [r, g, b] = self.as_rgb()
  let [r, g, b] = map([r, g, b], 'float2nr(round(v:val))')
  return printf('rgb(%d,%d,%d)', r, g, b)
endfunction

function! s:Color.as_hsl_str() abort
  let [h, s, l] = self.as_hsl()
  let [h, s, l] = map([h, s, l], 'float2nr(round(v:val))')
  return printf('hsl(%d,%d%%,%d%%)', h, s, l)
endfunction

function! s:Color.eq(color) abort
  return self.as_rgb() ==# a:color.as_rgb()
endfunction

function! s:Color.diff(color) abort
  let [r1, g1, b1] = self.as_rgb()
  let [r2, g2, b2] = a:color.as_rgb()
  return abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2)
endfunction

let s:RGB = deepcopy(s:Color)

function! s:RGB.as_rgb_hex() abort
  let [r, g, b] = map([self._r, self._g, self._b], 'float2nr(round(v:val))')
  return '#' . s:_nr2hex(r) . s:_nr2hex(g) . s:_nr2hex(b)
endfunction

function! s:RGB.as_rgb() abort
  return [self._r, self._g, self._b]
endfunction

function! s:RGB.as_hsl() abort
  return s:_rgb2hsl(self._r, self._g, self._b)
endfunction

let s:HSL = deepcopy(s:Color)

function! s:HSL.as_rgb_hex() abort
  let [r, g, b] = s:_hsl2rgb(self._h, self._s, self._l)
  let [r, g, b] = map([r, g, b], 'float2nr(round(v:val))')
  return '#' . s:_nr2hex(r) . s:_nr2hex(g) . s:_nr2hex(b)
endfunction

function! s:HSL.as_rgb() abort
  return s:_hsl2rgb(self._h, self._s, self._l)
endfunction

function! s:HSL.as_hsl() abort
  return [self._h, self._s, self._l]
endfunction


" Constructors

let s:RGB_HEX_RE = '\v^#(\x{3}(\x{3})?)$'
let s:RGB_RE = '\v^rgb\((\d+),\s*(\d+),\s*(\d+)\)$'
let s:HSL_RE = '\v^hsl\((\d+),\s*(\d+)\%,\s*(\d+)\%\)$'
function! s:parse(str) abort
  if type(a:str) !=# type('')
    throw 'vital: Color: parse(): invalid format: ' . a:str
  endif
  let m = matchlist(a:str, s:RGB_HEX_RE)
  if !empty(m)
    if strlen(m[1]) ==# 3
      let [r, g, b] = [str2float('0x' . m[1][0] . m[1][0]), str2float('0x' . m[1][1] . m[1][1]), str2float('0x' . m[1][2] . m[1][2])]
    else
      let [r, g, b] = [str2float('0x' . m[1][0:1]), str2float('0x' . m[1][2:3]), str2float('0x' . m[1][4:5])]
    endif
    return s:rgb(r, g, b)
  endif
  let m = matchlist(a:str, s:RGB_RE)
  if !empty(m)
    let [r, g, b] = [str2float(m[1]), str2float(m[2]), str2float(m[3])]
    return s:rgb(r, g, b)
  endif
  let m = matchlist(a:str, s:HSL_RE)
  if !empty(m)
    let [h, s, l] = [str2float(m[1]), str2float(m[2]), str2float(m[3])]
    return s:hsl(h, s, l)
  endif
  throw 'vital: Color: parse(): invalid format: ' . a:str
endfunction

function! s:rgb(r, g, b) abort
  if !s:_check_rgb_range(a:r, a:g, a:b)
    throw printf('vital: Color: rgb(): invalid value: r = %s, g = %s, b = %s',
    \ string(a:r), string(a:g), string(a:b))
  endif
  return extend(deepcopy(s:RGB), {'_r': a:r, '_g': a:g, '_b': a:b})
endfunction

function! s:_check_rgb_range(r, g, b) abort
  for n in [a:r, a:g, a:b]
    if type(n) !=# type(0) && type(n) !=# type(0.0)
    \ || 0 ># n || n ># 255
      return 0
    endif
  endfor
  return 1
endfunction

function! s:hsl(h, s, l) abort
  if !s:_check_hsl_range(a:h, a:s, a:l)
    throw printf('vital: Color: hsl(): invalid value: h = %s, s = %s, l = %s',
    \ string(a:h), string(a:s), string(a:l))
  endif
  return extend(deepcopy(s:HSL), {'_h': a:h, '_s': a:s, '_l': a:l})
endfunction

function! s:_check_hsl_range(h, s, l) abort
  for n in [a:h, a:s, a:l]
    if type(n) !=# type(0) && type(n) !=# type(0.0)
      return 0
    endif
  endfor
  if 0 ># a:h || a:h ># 360
    return 0
  endif
  if 0 ># a:s || a:s ># 100
    return 0
  endif
  if 0 ># a:l || a:l ># 100
    return 0
  endif
  return 1
endfunction


" Numeric Conversion Functions

" NOTE: min()/max() can't take Float numbers
function! s:_rgb2hsl(r, g, b) abort
  let [min, _, max] = sort([a:r, a:g, a:b], 'f')
  if min ==# max
    return [0, 0, 100.0 * min / 255.0]
  elseif max ==# a:r
    let h = 60.0 * (a:g - a:b) / (max - min)
  elseif max ==# a:g
    let h = 60.0 * (a:b - a:r) / (max - min) + 120.0
  else
    let h = 60.0 * (a:r - a:g) / (max - min) + 240.0
  endif
  if h < 0
    let h += 360
  endif
  let l = 100.0 * (max + min) / 2.0 / 255.0
  if l <=# 50.0
    let s = 100.0 * (max - min) / (max + min)
  else
    let s = 100.0 * (max - min) / (510.0 - max - min)
  endif
  return [h, s, l]
endfunction

function! s:_hsl2rgb(h, s, l) abort
  if a:l <# 50.0
    let l2 = a:l
  else
    let l2 = 100.0 - a:l
  endif
  let max = 2.55 * (a:l + l2 * (a:s / 100.0))
  let min = 2.55 * (a:l - l2 * (a:s / 100.0))
  if a:h <# 60.0
    let r = max
    let g = (a:h / 60.0) * (max - min) + min
    let b = min
  elseif a:h <# 120.0
    let r = ((120.0 - a:h) / 60.0) * (max - min) + min
    let g = max
    let b = min
  elseif a:h <# 180.0
    let r = min
    let g = max
    let b = ((a:h - 120.0) / 60.0) * (max - min) + min
  elseif a:h <# 240.0
    let r = min
    let g = ((240.0 - a:h) / 60.0) * (max - min) + min
    let b = max
  elseif a:h <# 300.0
    let r = ((a:h - 240.0) / 60.0) * (max - min) + min
    let g = min
    let b = max
  else
    let r = max
    let g = min
    let b = ((360.0 - a:h) / 60.0) * (max - min) + min
  endif
  return [r, g, b]
endfunction

let s:HEX_TABLE = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F']
function! s:_nr2hex(n) abort
  return s:HEX_TABLE[a:n / 16] . s:HEX_TABLE[a:n % 16]
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
" vim:set et ts=2 sts=2 sw=2 tw=0:
