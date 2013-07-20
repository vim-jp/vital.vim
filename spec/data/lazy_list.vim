source spec/base.vim

let g:LL = vital#of('vital').import('Data.LazyList')

Context Data.LazyList.from_list()
  It constructs lazy list
    let a = [1,2,3,4,5,6,7,8,9,10]
    let a_ = deepcopy(a)
    let b = g:LL.from_list(a)
    Should a == a_
    Should [] == g:LL.take(0, b)
    Should [1,2,3] == g:LL.take(3, b)
    Should [1,2,3] == g:LL.take(3, b)
    Should a == g:LL.take(len(a), b)
    Should a == g:LL.take(len(a)+10, b)
    Should a == a_
    unlet a
    unlet a_
    unlet b
  End

  It throws exception
    " no error...
"    ShouldThrow g:LL.from_list(1), /.*/
"    ShouldThrow g:LL.from_list("a"), /.*/
"    ShouldThrow g:LL.from_list({}), /.*/
    ShouldThrow g:LL.from_list([1,2,3], [4,5,6]), /.*/
  End
  It constructs lazy list with any type
    for a in [
    \  [0,1,2,3,4,5,6,7,8,9,10],
    \   ['a','b','c','d','e'],
    \   [0, "123", {}, [], 123]
    \]
      let b = g:LL.from_list(a)
      for i in range(len(a)+3)
        if i == 0
          Should [] == g:LL.take(i, b)
        elseif i < len(a)
          Should a[0:i-1] == g:LL.take(i, b)
        else
          Should a == g:LL.take(i, b)
        endif
      endfor
      unlet b
      unlet i
      unlet a
    endfor
  End
End

Context Data.LazyList.iterate()
  It constructs lazy list
    let a = [1,2,3,4,5,6,7,8,9,10]
    let b = g:LL.iterate(1, 'v:val + 1')

    Should [] == g:LL.take(0, b)
    Should [1,2,3] == g:LL.take(3, b)
    Should a == g:LL.take(len(a), b)
    for i in range(len(a)+1)
      let b = g:LL.iterate(1, 'v:val + 1')
      if i == 0
        Should [] == g:LL.take(i, b)
      else
        Should a[0:i-1] == g:LL.take(i, b)
      endif
    endfor
    unlet a
    unlet b
    unlet i
  End
End

Context Data.LazyList.file_readlines()

  if 0 " issue #93
  " requires vimproc
  It constructs lazy list
    let tmpfile = tempname()
    let lines = []
    let lines += ["1"]
    let lines += ["2"]
    let lines += ["3"]
    let lines += ["4ABCDEFG"]
    let lines += [""]
    let lines += ["6ABCDEFG"]
    let lines += ["7"]
    let lines += ["8abc"]
    let lines += ["012345"]
    for i in range(100)
      let lines += [printf("%d", i)]
    endfor
    call writefile(lines, tmpfile)
    let b = g:LL.file_readlines(tmpfile)
    Should [] == g:LL.take(0, b)
    Should ["1", "2", "3"] == g:LL.take(3, b)

    for i in range(len(lines))
      if i == 0
        Should [] == g:LL.take(i, b)
      elseif i < len(lines)
        Should lines[0:i-1] == g:LL.take(i, b)
      else
        Should lines == g:LL.take(i, b)
        break
      endif
    endfor
    Should [] == g:LL.take(0, b)
    call delete(tmpfile)
  End
  endif

  It throws exception
    ShouldThrow g:LL.file_readlines({}), /.*/
    ShouldThrow g:LL.file_readlines([]), /.*/
    let i = 0
    while 1
      let i = i + 1
      let fname = printf("/tmp/__non_exist_file_%d", i)
      if !filereadable(fname)
        ShouldThrow g:LL.file_readlines(""), /.*/
        break
      endif
    endwhile
  End
End


