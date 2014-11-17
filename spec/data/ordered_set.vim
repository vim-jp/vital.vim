source spec/base.vim

let g:OrderedSet = vital#of('vital').import('Data.OrderedSet')

Context Data.OrderedSet.push()
  It adds an element to the last of an OrderedSet
    let g:set = g:OrderedSet.new()
    Should g:set.to_list() == []
    call g:set.push(1)
    Should g:set.to_list() == [1]
    call g:set.push(2)
    Should g:set.to_list() == [1,2]
    call g:set.push(3)
    Should g:set.to_list() == [1,2,3]
    call g:set.push(1)
    Should g:set.to_list() == [1,2,3]
  End
End

Context Data.OrderedSet.unshift()
  It adds an element to the first of an OrderedSet
    let g:set = g:OrderedSet.new()
    Should g:set.to_list() == []
    call g:set.unshift(1)
    Should g:set.to_list() == [1]
    call g:set.unshift(2)
    Should g:set.to_list() == [2,1]
    call g:set.unshift(3)
    Should g:set.to_list() == [3,2,1]
    call g:set.unshift(1)
    Should g:set.to_list() == [3,2,1]
  End
End

Context Data.OrderedSet.append()
  It appends an element to the last of an OrderedSet
    let g:set = g:OrderedSet.new()
    Should g:set.to_list() == []
    call g:set.append([1,2,3])
    Should g:set.to_list() == [1,2,3]
    call g:set.append([2,3,4,5])
    Should g:set.to_list() == [1,2,3,4,5]
  End
End

Context Data.OrderedSet.prepend()
  It prepends an element to the first of an OrderedSet
    let g:set = g:OrderedSet.new()
    Should g:set.to_list() == []
    call g:set.prepend([1,2,3])
    Should g:set.to_list() == [1,2,3]
    call g:set.prepend([-1,0,1])
    Should g:set.to_list() == [-1,0,1,2,3]
  End
End

Context Data.OrderedSet.clear()
  It makes OrderedSet empty
    let g:set = g:OrderedSet.new()
    call g:set.push(1)
    call g:set.push(2)
    call g:set.push(3)
    call g:set.clear()
    Should g:set.to_list() == []
    Should g:set.empty()
  End
End

Context Data.OrderedSet.empty()
  It returns boolean value if an OrderedSet is empty
    let g:set = g:OrderedSet.new()
    Should g:set.empty()
    call g:set.push(1)
    Should !g:set.empty()
    call g:set.clear()
    Should g:set.empty()
  End
End



function! IdentifyClass(class) abort
    return a:class.name . a:class.value
endfunction
function! CreateClass(name, value) abort
    return {'name': a:name, 'value': a:value,
    \       'mem1': localtime(), 'mem2': localtime(),
    \       'mem3': localtime()}
endfunction

Context Fn_identifier
  It stringifies to a key name of a Dictionary
    let g:set = g:OrderedSet.new({'Fn_identifier': 'IdentifyClass'})
    call g:set.append([
    \   CreateClass('FooClass', 'foo'),
    \   CreateClass('BarClass', 'bar'),
    \   CreateClass('BazClass', 'baz'),
    \   CreateClass('FooClass', 'hoge'),
    \   CreateClass('FooClass', 'foo'),
    \   CreateClass('BazClass', 'baz'),
    \])
    Should g:set.to_list() == [
    \   CreateClass('FooClass', 'foo'),
    \   CreateClass('BarClass', 'bar'),
    \   CreateClass('BazClass', 'baz'),
    \   CreateClass('FooClass', 'hoge'),
    \]
    Should g:set.has(CreateClass('FooClass', 'foo'))
    Should g:set.has(CreateClass('BarClass', 'bar'))
    Should g:set.has(CreateClass('BazClass', 'baz'))
    Should g:set.has(CreateClass('FooClass', 'hoge'))
    Should !g:set.has(CreateClass('FooClass', 'bar'))
  End
End

Context Data.OrderedSet.has()
  It returns if an OrderedSet has a given element
    let g:set = g:OrderedSet.new()
    Should !g:set.has(1)
    call g:set.append([1,2,3])
    Should g:set.has(1)
  End
End

Context Data.OrderedSet.has_id()
  It returns if an OrderedSet has a given id of element
    " Default Fn_identifier is 'string'.
    let g:set = g:OrderedSet.new()
    Should !g:set.has_id(string("foo"))
    call g:set.append(["foo", "bar", "baz"])
    Should g:set.has_id(string("foo"))
  End
End

Context Data.OrderedSet.remove()
  It removes an element from OrderedSet
    let g:set = g:OrderedSet.new()
    call g:set.push(1)
    call g:set.remove(1)
    Should g:set.empty()

    let g:set = g:OrderedSet.new()
    call g:set.prepend([1,2])
    call g:set.remove(1)
    Should g:set.to_list() == [2]

    let g:set = g:OrderedSet.new()
    call g:set.prepend([1,2])
    call g:set.remove(2)
    Should g:set.to_list() == [1]

    let g:set = g:OrderedSet.new()
    call g:set.append([1,2])
    call g:set.remove(1)
    Should g:set.to_list() == [2]

    let g:set = g:OrderedSet.new()
    call g:set.append([1,2])
    call g:set.remove(2)
    Should g:set.to_list() == [1]
  End

  It is safe to remove middle element of OrderedSet
    let g:set = g:OrderedSet.new()
    call g:set.prepend([1,2,3])
    call g:set.remove(2)
    Should g:set.to_list() == [1,3]
    call g:set.unshift(0)
    Should g:set.to_list() == [0,1,3]
    call g:set.remove(1)
    Should g:set.to_list() == [0,3]

    let g:set = g:OrderedSet.new()
    call g:set.append([1,2,3])
    call g:set.remove(2)
    Should g:set.to_list() == [1,3]
    call g:set.push(4)
    Should g:set.to_list() == [1,3,4]
    call g:set.remove(3)
    Should g:set.to_list() == [1,4]
  End

  It does anything if OrderedSet does not have a given element
    let g:set = g:OrderedSet.new()
    call g:set.push(1)
    try
      call g:set.remove(2)
      Should 1
      Should g:set.to_list() == [1]
    catch
      Should 0
    endtry
  End
End
