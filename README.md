# vital.vim [![Build Status](https://travis-ci.org/vim-jp/vital.vim.svg?branch=master)](https://travis-ci.org/vim-jp/vital.vim)

A comprehensive Vim utility functions for Vim plugins.

This is like a plugin which has both aspects of
[Bundler](http://gembundler.com/) and [jQuery](http://jquery.com/) at the same
time.

## Targets

If you are a Vim user who don't make Vim plugins, please ignore this page.

If you are a Vim plugin author, please check this out.

## What vital.vim provides

* [Assertion](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-assertion.txt)
* [Bitwise](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-bitwise.txt)
* [Data.Base64](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-data-base64.txt)
* [Data.Collection](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-data-collection.txt)
* [Data.Dict](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-data-dict.txt)
* [Data.LazyList](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-data-lazylist.txt)
* [Data.List](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-data-list.txt)
* [Data.OrderedSet](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-data-ordered_set.txt)
* [Data.String](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-data-string.txt)
* [Data.Tree](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-data-tree.txt)
* [Database.SQLite](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-database-sqlite.txt)
* [DateTime](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-date_time.txt)
* [Experimental.Functor](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-experimental-functor.txt)
* [Interpreter.Brainf__k](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-interpreter-brainf__k.txt)
* [Locale.Message](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-locale-message.txt)
* [Lua.Prelude](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-lua-prelude.txt)
* [Mapping](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-mapping.txt)
* [Math](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-math.txt)
* [OptionParser](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-option_parser.txt)
* [Prelude](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-prelude.txt)
* [Process](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-process.txt)
* [ProcessManager](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-process_manager.txt)
* [Random](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-random.txt)
* [Random.Xor128](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-random-xor128.txt)
* [Random.Mt19937ar](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-random-mt19937ar.txt)
* [System.Cache](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-system-cache.txt)
* [System.File](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-system-file.txt)
* [System.Filepath](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-system-filepath.txt)
* [Text.CSV](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-text-csv.txt)
* [Text.INI](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-text-ini.txt)
* [Text.Lexer](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-text-lexer.txt)
* [Text.LTSV](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-text-ltsv.txt)
* [Text.Parser](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-text-parser.txt)
* Text.Sexp
* [Vim.Buffer](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-vim-buffer.txt)
* [Vim.BufferManager](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-vim-buffer_manager.txt)
* [Vim.Compat](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-vim-compat.txt)
* [Vim.Message](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-vim-message.txt)
* Vim.Search
* [Web.HTML](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-web-html.txt)
* [Web.HTTP](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-web-http.txt)
* [Web.JSON](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-web-json.txt)
* Web.URI
* [Web.XML](https://github.com/vim-jp/vital.vim/blob/master/doc/vital-web-xml.txt)
* ... and more ...


## Let's get started

### Install modules for your own plugin

Use `:Vitalize` to install modules.
Please see [the help](https://github.com/vim-jp/vital.vim/blob/master/doc/vitalizer.txt) for more details.

```vim
:Vitalize --name=your_plugin_name $HOME/.vim/bundle/your_plugin_dir/
```

You can also install only specified modules; recommended for making your
repository size small, assuming you are going to upload it to a remote
repository

```vim
:Vitalize --name=your_plugin_name $HOME/.vim/bundle/your_plugin_dir/ Data.String Data.List
```

### Use vital functions

Assuming your Vim plugin name is `ujihisa`. You can define your utility
function set `ujihisa#util` just by

```vim
let s:V = vital#of('ujihisa')
function! ujihisa#util#system(...)
  return call(s:V.system, a:000, s:V)
endfunction
```

and then you can call functions by `ujihisa#util#system()`, without taking care
of `vital.vim` itself. It's all hidden.

Vital has module system. The below is an example to import/load a module
`Data.OrderedSet` and to call a function `f()` of the module.

```vim
" Recommented way
let s:V = vital#of('ujihisa')
let s:O = s:V.import('Data.OrderedSet')
call s:O.f()
```

or

```vim
" Recommended way only if you rarely use the module
let s:V = vital#of('ujihisa')
call s:V.load('Data.OrderedSet')
call s:V.Data.OrderedSet.f()
```

or

```vim
" Available, but we don't recommend this very much
let s:V = vital#of('ujihisa')
call s:V.import('Data.OrderedSet', s:)
call s:f()
```

We recommend you to use a capital letter for a Vital module dictionary to assign.

## If you want to become a vital developer

[Become a vital.vim Developer](https://github.com/vim-jp/vital.vim/wiki/Become-a-vital.vim-Developer)

## References

* [How to use vital.vim (in Japanese)](http://rbtnn.github.io/how-to-use-vital.vim/)
    * This is beautiful
* [Delegation in Vim script](http://ujihisa.blogspot.com/2011/02/delegation-in-vim-script.html)
* [Core concept of vital (in Japanese)](http://d.hatena.ne.jp/thinca/20110310/1299768323)
* [How to make a vital module (in Japanese)](http://d.hatena.ne.jp/thinca/20110311/1299769233)
* [Let's use vital.vim (in Japanese)](http://qiita.com/rbtnn/items/deb569ebc94d5172a5e5)

## Authors

* ![](https://secure.gravatar.com/avatar/3b83f8f7a25019f3ee01791df024bf3c)
  [thinca](http://github.com/thinca)
* ![](https://secure.gravatar.com/avatar/d9d0ceb387e3b6de5c4562af78e8a910)
  [ujihisa](http://github.com/ujihisa) (Tatsuhiro Ujihisa)
* ![](https://secure.gravatar.com/avatar/5fdf83c448b8503add52517c7de0e3cc)
  [tyru](http://github.com/tyru)
* ![](https://secure.gravatar.com/avatar/1ba93fd9e39ebf48777f217c38e768fd)
  [mattn](http://github.com/mattn)
* ![](https://secure.gravatar.com/avatar/7f5a1bfaf8b64cbcdfaf82a7de92506b)
  [Shougo](http://github.com/shougo)
* ... and lots more <https://github.com/vim-jp/vital.vim/graphs/contributors>

## License

[NYSL](http://www.kmonos.net/nysl/index.en.html)

Japanese original text: <http://www.kmonos.net/nysl/>

### What's NYSL? and Why did we chose it?

NYSL is a very loose license like a [Beer License](http://en.wikipedia.org/wiki/Beerware), or more like [WTFPL](http://en.wikipedia.org/wiki/WTFPL).
See [NYSL](http://www.kmonos.net/nysl/NYSL.TXT) for details.  (English and Japanese)

First, vital.vim is a bundling (static) library.
We think everyone should be able to use it easily, without worrying about
licensing stuff too much.

Second, In Japan, *Strict* Public Domain might be invalid.
You outside Japan may interpret simply the license as Public Domain.

That's why we chose NYSL.

(See <https://github.com/vim-jp/vital.vim/issues/26> about the discussion.)
