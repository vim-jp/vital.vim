
let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V)
	let s:assert_config = {
				\   'equal_separator' : ['<=>','<=>'],
				\   'not_equal_separator' : ['<!>','<!>'],
				\   'enable' : 1,
				\ }
	let s:V = a:V
	let s:L = s:V.import('Text.Lexer')
	let s:lexer_obj = s:L.lexer([
				\ s:assert_config.equal_separator,
				\ s:assert_config.not_equal_separator,
				\ ['scriptfunc', 's:[0-9a-zA-Z_]\+'],
				\ ['ident', '[0-9a-zA-Z_]\+'],
				\ ['ws', '\s\+'],
				\ ['d_string', '"\(\\.\|[^"]\)*"'],
				\ ['s_string', '''\(''''\|[^'']\)*'''],
				\ ['otherwise', '.']
				\ ])
endfunction

function! s:_vital_depends()
	return ['Text.Lexer']
endfunction

function! s:_outputter(dict) " {{{
	if ! a:dict.is_success
		echohl Error
	endif
	echo  printf("%s %s :%s",
				\ a:dict.cmd,
				\ a:dict.expr,
				\ (a:dict.is_success ? 'Succeeded' : 'Failed'),
				\ )
	if ! a:dict.is_success
		echo  printf("> assert_point: %s", a:dict.assert_point)
		echo  printf("> lhs: %s", a:dict.lhs)
		echo  printf("> rhs: %s", a:dict.rhs)
		echohl None

		throw 'vital: Assertion: EXIT_FAILURE'
	endif
endfunction " }}}
function! s:_redir(cmd) " {{{
	let oldverbosefile = &verbosefile
	set verbosefile=
	redir => res
	silent! execute a:cmd
	redir END
	let &verbosefile = oldverbosefile
	return res
endfunction " }}}
function! s:_define_scriptfunction(fname) " {{{
	let scriptnames_list = map(split(s:_redir('scriptnames'),"\n"),'matchlist(v:val,''^\s*\(\d\+\)\s*:\s*\(.*\)\s*$'')[:2]')
	let targets = filter(copy(scriptnames_list),printf('fnamemodify(get(v:val,2,""),":p") ==# fnamemodify(%s,":p")',string(expand('%'))))
	if ! empty(targets)
		if exists(printf("*<SNR>%d_%s", targets[0][1], a:fname[2:]))
			execute printf('let %s = function(%s)',a:fname,string(printf("<SNR>%d_%s",targets[0][1],a:fname[2:])))
		endif
	endif
endfunction " }}}
function! s:_assertion( q_args, local, scriptfilename, about_currline, cmd) " {{{
	for key in keys(a:local)
		execute printf('let %s = %s',key,string(a:local[key]))
	endfor
	if s:assert_config.enable
		let tkns = s:lexer_obj.exec(a:q_args)
		let is_lhs = 1
		let is_not = 0
		let lhs_tkns = []
		let rhs_tkns  = []
		for tkn in tkns
			if is_lhs && tkn.label == s:assert_config.equal_separator[0]
				let is_lhs = 0
				let is_not = 0
			elseif is_lhs && tkn.label == s:assert_config.not_equal_separator[0]
				let is_lhs = 0
				let is_not = 1
			elseif is_lhs
				let lhs_tkns  += [tkn]
			else
				let rhs_tkns  += [tkn]
			endif
			if tkn.label ==# 'scriptfunc'
				call s:_define_scriptfunction(tkn.matched_text)
			endif
		endfor

		let lhs_text = join(map(lhs_tkns ,'v:val.matched_text'),'')
		let rhs_text = join(map(rhs_tkns ,'v:val.matched_text'),'')
		let is_success = 0
		if type("") == type(eval(lhs_text))
			let is_success = eval(lhs_text) ==# eval(rhs_text)
		else
			let is_success = eval(lhs_text) == eval(rhs_text)
		endif

		let is_success = is_not ? ! is_success : is_success

		call s:_outputter({
					\ 'config' : copy(s:assert_config),
					\ 'cmd' : a:cmd,
					\ 'is_not' : is_not,
					\ 'is_success' : is_success,
					\ 'lhs' : lhs_text,
					\ 'rhs' : rhs_text,
					\ 'expr' : a:q_args,
					\ 'assert_point' : a:about_currline,
					\ })
	endif
endfunction " }}}

function! s:define(cmd_name,...) " {{{
	if (0 < len(a:000)) ? a:1 : 0
		execute 'command! -buffer -nargs=1 '.a:cmd_name.' try | throw 1 | catch | call s:_assertion(<q-args>,(exists(''l:'')?eval(''l:''):{}),expand(''%''), v:throwpoint, '.string(a:cmd_name).') | endtry'
	else
		execute 'command! -buffer -nargs=1 '.a:cmd_name
	endif
endfunction " }}}
function! s:set_config(config) " {{{
	" TODO
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo

"  vim: set ts=2 sts=2 sw=2 ft=vim fdm=marker ff=unix :
