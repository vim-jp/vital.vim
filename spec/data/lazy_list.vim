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
    Should [4,5,6] == g:LL.take(3, b)
    Should [7,8,9,10] == g:LL.take(len(a), b)
    Should [] == g:LL.take(len(a)+10, b)
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
      for i in range(len(a)+3)
        let b = g:LL.from_list(a)
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
    Should [4,5] == g:LL.take(2, b)
    Should [] == g:LL.take(0, b)
    Should [6,7,8] == g:LL.take(3, b)
    Should [9,10] == g:LL.take(6, b)
    Should [] == g:LL.take(4, b)
    for i in range(len(a)+1)
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

  " vimproc
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

    let ed = 3
    for j in range(len(lines))
      let i = j % 3
      let st = ed
      let ed = st + j

      if i == 0
        Should [] == g:LL.take(i, b)
      elseif ed < len(lines)
        Should lines[st:ed-1] == g:LL.take(i, b)
      else
        Should [] == g:LL.take(i, b)
        break
      endif
    endfor
    Should [] == g:LL.take(0, b)
    Should [] == g:LL.take(1, b)
    Should [] == g:LL.take(5, b)
    call delete(tmpfile)
  End

  It throws exception
    ShouldThrow g:LL.file_readlines({}), /.*/
    ShouldThrow g:LL.file_readlines([]), /.*/
    ShouldThrow g:LL.file_readlines(/tmp/__non_exist_file__), /.*/
  End
End


