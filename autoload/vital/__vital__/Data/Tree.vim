let s:save_cpo = &cpo
set cpo&vim

function! s:_renderer(idx, tree) abort
  let lines = []
  let value = string(a:tree)
  let children = []
  if type({}) is type(a:tree)
    let value = string(get(a:tree, 'token', ''))
    let children = get(a:tree, 'children', [])
  endif
  let lines += [ join(repeat(['|'], a:idx), ' ') . (a:idx is 0 ? '' : ' ') . '*' . ' ' . value ]
  for cidx in range(0, len(children) - 1)
    if cidx isnot len(a:tree.children) - 1
      let lines += [ join(repeat(['|'], (a:idx + 1)), ' ') . ' ' . '/' ]
      let lines += s:_renderer(a:idx+1, children[cidx])
      let lines += [ join(repeat(['|'], a:idx + 1), ' ') ]
    else
      let lines += s:_renderer(a:idx, children[cidx])
    endif
  endfor
  return lines
endfunction

function! s:new(token, ...) abort
  if type(a:token) == type({}) && has_key(a:token,'token') && has_key(a:token,'children')
    let obj = a:token
  else
    let obj = { 'token': a:token , 'children': a:0 > 0
    \ ? ( a:0 == 1 ? (type(a:1) == type([]) ? a:1 : [(a:1)])
    \              : a:000
    \   )
    \ : [] }
  endif

  function! obj.addchild(...) dict abort
    let self.children += map(copy(a:000), 'copy(v:val)')
    return self
  endfunction

  function! obj.todict() dict abort
    return { type(self.token) == type('')
    \  ? self.token : string(self.token)
    \  : map(copy(self.children),'type(v:val) == type({}) ? v:val.todict() : string(v:val)') }
  endfunction

  function! obj.preorder_traversal() dict abort
    let tkns = []
    let tkns += [(self.token)]
    for child in self.children
      let tkns += s:new(child).preorder_traversal()
      unlet child
    endfor
    return tkns
  endfunction

  function! obj.inorder_traversal() dict abort
    let tkns = []
    if ! empty(self.children)
      let tkns += s:new(get(self.children, 0, '')).inorder_traversal()
    endif
    let tkns += [(self.token)]
    if ! empty(self.children)
      let tkns += s:new(get(self.children, 1, '')).inorder_traversal()
    endif
    return tkns
  endfunction

  function! obj.postorder_traversal() dict abort
    let tkns = []
    for child in self.children
      let tkns += s:new(child).preorder_traversal()
      unlet child
    endfor
    let tkns += [(self.token)]
    return tkns
  endfunction

  function! obj.renderer() dict abort
    return reverse(s:_renderer(0, self))
  endfunction

  return copy(obj)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
