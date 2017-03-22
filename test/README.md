How to test vital.vim
=====================

All tests for vital.vim modules are now written with [themis.vim](https://github.com/thinca/vim-themis).  When you want to run tests, you should install it in advance.

```sh
$ cd /path/to/vital.vim
$ git clone https://github.com/thinca/vim-themis.git
```

Now you can run tests with `themis` executable file.

```sh
$ ./vim-themis/bin/themis
```

If you want to run tests for a specific module, specify the test file corresponding to the module.
Below runs tests for `Data.List` module.

```sh
$ ./vim-themis/bin/themis test/Data/List.vimspec
```

Please read [a documentation of themis.vim](https://github.com/thinca/vim-themis/blob/master/doc/themis.txt) for more detail.
