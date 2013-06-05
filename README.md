# vital.vim

A comprehensive Vim utility functions for Vim plugins.

This is like a plugin which has both aspects of [Bundler](http://gembundler.com/) and [jQuery](http://jquery.com/) at the same time.

## Targets

If you are a Vim user who don't make Vim plugins, please ignore this page.

If you are a Vim plugin author, please check this out.

## What vital.vim provides

* `system()`
    * If user has `vimproc`, this uses `vimproc#system()`, otherwise just the Vim builtin `system()`.
* ... (all public functions in [unite](https://github.com/Shougo/unite.vim)/util.

## How to use

Assuming your Vim plugin name is `ujihisa`. You can define your utility function set `ujihisa#util` just by

    let V = vital#of('ujihisa')
    function! ujihisa#util#system(...)
      return call(V.system, a:000, V)
    endfunction

and then you can call functions by `ujihisa#util#system()`, without taking care of `vital.vim` itself. It's all hidden.

Vital has module system. The below is an example to import/load a module `data/ordered_set` and to call a function `f()` of the module.

    let V = vital#of('ujihisa')
    let O = V.import('Data.OrderedSet')
    call O.f()

or

    let V = vital#of('ujihisa')
    call V.load('Data.OrderedSet')
    call V.Data.OrderedSet.f()

or

    let V = vital#of('ujihisa')
    call V.import('Data.OrderedSet', s:)
    call s:f()

We recommend you to use a capital letter for a Vital module dictionary to assign.

## If you want to become a vital committer
[Become a vital.vim Developer](https://github.com/vim-jp/vital.vim/wiki/Become-a-vital.vim-Developer)

## References

* [Delegation in Vim script](http://ujihisa.blogspot.com/2011/02/delegation-in-vim-script.html)
* [Core concept of vital (in Japanese)](http://d.hatena.ne.jp/thinca/20110310/1299768323)
* [How to make a vital module (in Japanese)](http://d.hatena.ne.jp/thinca/20110311/1299769233)

## Author

Tatsuhiro Ujihisa

## License

[NYSL](http://www.kmonos.net/nysl/)

### What's NYSL? and Why you chose it?

NYSL is a very loose license like a [Beer License](http://en.wikipedia.org/wiki/Beerware), or more like [WTFPL](http://en.wikipedia.org/wiki/WTFPL).
See [NYSL](http://www.kmonos.net/nysl/NYSL.TXT) for details.  (English and Japanese)

First, vital.vim is a bundling(static) library.
We think everyone should use it easily, without the care about license.

Second, In Japan, *Strict* Public Domain might be invalid.
You outside Japan may interpret simply the license as Public Domain.

That's why we chose NYSL.

(See <https://github.com/vim-jp/vital.vim/issues/26> about the discussion.)
