# vital.vim

A comprehensive Vim utility functions for Vim plugins

## Targets

If you are a Vim user who don't make Vim plugins, please ignore this page.

If you are a Vim plugin author, please check `vital.vim`.

## What vital.vim provides

* `system()`
    * If user has `vimproc`, this uses `vimproc#system()`, otherwise just the Vim builtin `system()`.
* ...

## How to use

Assuming your Vim plugin name is `ujihisa`. You can define your utility function set `ujihisa#util` just by

    function! ujihisa#util()
      return vital#of('_49f672')
    endfunction

and then you can call functions by `ujihisa#util().system()`, without taking care of `vital.vim` itself. It's all hidden.

## Author

Tatsuhiro Ujihisa
