" Utilities for keymapping.

let s:save_cpo = &cpo
set cpo&vim



" TODO:
" - document for argument variable names.
" - parsing functions
" - s:split_to_keys() in arpeggio.vim
" - s:key2char() in eskk.vim
" - support maparg()'s {dict}
" - builder object: .lhs(), .rhs(), .modes(), ...
" - move functions from eskk.vim(autoload/eskk/map.vim), emap.vim(autoload/emap.vim)




function! s:options_dict2raw(maparg)
    " Convert dictionary to Vim's :map options.
    return
    \   (get(a:maparg, 'expr')      ? '<expr>'    : '')
    \   . (get(a:maparg, 'buffer')  ? '<buffer>'  : '')
    \   . (get(a:maparg, 'silent')  ? '<silent>'  : '')
    \   . (get(a:maparg, 'special') ? '<special>' : '')
    \   . (get(a:maparg, 'script')  ? '<script>'  : '')
    \   . (get(a:maparg, 'unique')  ? '<unique>'  : '')
endfunction

function! s:options_chars2raw(chars)
    let table = {
    \   's': '<silent>',
    \   'S': '<script>',
    \   'e': '<expr>',
    \   'b': '<buffer>',
    \   'u': '<unique>',
    \}
    return join(map(split(a:chars, '\zs'), 'get(table, v:val, "")'), '')
endfunction

function! s:options_chars2dict(chars)
    return {
    \   'expr': (stridx(a:chars, 'e') isnot -1),
    \   'buffer': (stridx(a:chars, 'b') isnot -1),
    \   'silent' : (stridx(a:chars, 's') isnot -1),
    \   'special' : (stridx(a:chars, 'S') isnot -1),
    \   'unique': (stridx(a:chars, 'u') isnot -1),
    \   'noremap': (stridx(a:chars, 'r') is -1),
    \}
endfunction



function! s:execute_map_command(mode, dict, lhs, rhs)
    " s:get_map_command() may return empty string for invalid arguments.
    " But :execute '' does not do anything.
    execute s:get_map_command(a:mode, a:dict, a:lhs, a:rhs)
endfunction

function! s:get_map_command(mode, dict, lhs, rhs)
    return call('s:__get_command', ['map'] + a:000)
endfunction

function! s:execute_abbr_command(mode, dict, lhs, rhs)
    " s:get_abbr_command() may return empty string for invalid arguments.
    " But :execute '' does not do anything.
    execute s:get_abbr_command(a:mode, a:dict, a:lhs, a:rhs)
endfunction

function! s:get_abbr_command(mode, dict, lhs, rhs)
    return call('s:__get_command', ['abbr'] + a:000)
endfunction

function! s:execute_unmap_command(mode, dict, lhs)
    " s:get_unmap_command() may return empty string for invalid arguments.
    " But :execute '' does not do anything.
    execute s:get_unmap_command(a:mode, a:dict, a:lhs)
endfunction

function! s:get_unmap_command(mode, dict, lhs)
    return call('s:__get_command', ['unmap'] + a:000)
endfunction



function! s:__get_command(type, mode, dict, lhs, rhs)
    if type(a:dict) != type({})
    \   || !s:is_mode_char(a:mode)
    \   || a:lhs ==# ''
    \   || a:rhs ==# ''
        return ''
    endif

    let noremap = get(a:dict, 'noremap', 0)
    return join([
    \   a:mode . (noremap ? 'nore' : '') . a:type,
    \   s:mapopt_dict2raw(a:dict),
    \   a:lhs,
    \   a:rhs,
    \])
endfunction


function! s:get_all_modes()
    return 'nvoiclxs'
endfunction

function! s:get_all_modes_list()
    return split(s:get_all_modes(), '\zs')
endfunction

function! s:is_mode_char(char)
    return a:char =~# '^['.s:get_all_modes().']$'
endfunction



let &cpo = s:save_cpo
