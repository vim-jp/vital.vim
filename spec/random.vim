source spec/base.vim

let g:R = vital#of('vital').import('Random')

Context Random.next()
  It returns a random number.
    let random = R.new('Xor128', [])
    for _ in range(10)
      let x = random.next()
      Should type(x) == type(0)
    endfor
    unlet x
  End
  It returns n random numbers.
    let random = R.new('Xor128', [])
    for n in range(10)
      let x = random.next(n)
      Should type(x) == type([])
      Should len(x) == n
    endfor
    unlet x
  End
End

Context Random.generate_canonical()
  It returns a random float number in 0.0 - 1.0.
    let random = R.new('Xor128', [])
    for _ in range(1000)
      let x = random.generate_canonical()
      Should 0.0 <= x && x < 1.0
    endfor
    unlet x
  End
End

Context Random.range()
  It returns a random number in specified range.
    let random = R.new('Xor128', [])
    for _ in range(100)
      let x = random.range(10)
      Should 0 <= x && x < 10
      let x = random.range(-10)
      Should -10 < x && x <= 0
      let x = random.range(-10, 10)
      Should -10 <= x && x < 10
      let x = random.range(10, -10)
      Should -10 < x && x <= 10
    endfor
    unlet x
  End
  It returns a random float number in specified range.
    let random = R.new('Xor128', [])
    for _ in range(100)
      let x = random.range(10.0)
      Should 0.0 <= x && x < 10.0
      let x = random.range(-10.0)
      Should -10.0 < x && x <= 0.0
      let x = random.range(-10.0, 10.0)
      Should -10.0 <= x && x < 10.0
      let x = random.range(10.0, -10.0)
      Should -10.0 < x && x <= 10.0
    endfor
    unlet x
  End
End

Context Random.bool()
  It returns a random number in specified range.
    let random = R.new('Xor128', [])
    for _ in range(100)
      let x = random.bool()
      Should x is 0 || x is 1
    endfor
    unlet x
  End
End

Context Random.sample()
  It returns a random element from the list.
    let random = R.new('Xor128', [])
    let list = range(10)
    for _ in range(100)
      let x = random.sample(list)
      Should 0 <= index(list, x)
    endfor
    unlet x
  End
  It returns n random elements from the list.
    let random = R.new('Xor128', [])
    let list = range(10) + range(10)
    for _ in range(100)
      let n = _ % len(list)
      let xs = random.sample(list, n)
      Should type(xs) == type([])
      Should len(xs) == n
      let copy_list = copy(list)
      for x in xs
        let idx = index(copy_list, x)
        Should 0 <= idx
        call remove(copy_list, idx)
      endfor
    endfor
    unlet xs
    unlet x
  End
End

Context Random.shuffle()
  It shuffles the list.
    let random = R.new('Xor128', [])
    for _ in range(100)
      let list = range(100)
      let copy_list = copy(list)
      let result_list = random.shuffle(copy_list)
      Should result_list is copy_list
      Should sort(list) == sort(result_list)
    endfor
  End
End

