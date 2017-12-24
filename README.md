# vital.vim [![Build Status](https://travis-ci.org/vim-jp/vital.vim.svg?branch=master)](https://travis-ci.org/vim-jp/vital.vim) [![Build status](https://ci.appveyor.com/api/projects/status/078w3wc2eocwa558/branch/master?svg=true)](https://ci.appveyor.com/project/vim-jp/vital-vim/branch/master) [![codecov](https://codecov.io/gh/vim-jp/vital.vim/branch/master/graph/badge.svg)](https://codecov.io/gh/vim-jp/vital.vim)

[![Join the chat at https://gitter.im/vim-jp/vital.vim](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/vim-jp/vital.vim?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

A comprehensive Vim utility functions for Vim plugins.

This is like a plugin which has both aspects of
[Bundler](http://gembundler.com/) and [jQuery](http://jquery.com/) at the same
time.

Modules in vital.vim basically support Vim 7.4 or later. And some modules have stricter requirements and additional dependencies.
Please read the docs of each module before using them.

## Targets of this plugin

If you are a Vim user who doesn't make Vim plugins, please ignore this page.

If you are a Vim plugin author, please check this out.

## What vital.vim provides

Module						 | Description
------------------------------------------------ | ------------------------------
[Assertion](doc/vital/Assertion.txt)		 | assertion library
[Async.Promise](doc/vital/Async/Promise.txt)	 | An asynchronous operation like ES6 Promise
[Bitwise](doc/vital/Bitwise.txt)		 | bitwise operators
[ConcurrentProcess](doc/vital/ConcurrentProcess.txt)	 | manages processes concurrently with vimproc
[Data.Base64](doc/vital/Data/Base64.txt)	 | base64 utilities library
[Data.BigNum](doc/vital/Data/BigNum.txt)	 | multi precision integer library
[Data.Closure](doc/vital/Data/Closure.txt)	 | Provide Closure object
[Data.Collection](doc/vital/Data/Collection.txt) | Utilities both for list and dict
[Data.Counter](doc/vital/Data/Counter.txt) | Counter library to support convenient tallies
[Data.Dict](doc/vital/Data/Dict.txt)		 | dictionary utilities library
[Data.Either](doc/vital/Data/Either.txt)	 | either value library
[Data.LazyList](doc/vital/Data/LazyList.txt)	 | lazy list including file io
[Data.List](doc/vital/Data/List.txt)		 | list utilities library
[Data.Optional](doc/vital/Data/Optional.txt)	 | optional value library
[Data.OrderedSet](doc/vital/Data/OrderedSet.txt)| ordered collection library
[Data.String](doc/vital/Data/String.txt)	 | string utilities library
[Data.Tree](doc/vital/Data/Tree.txt)		 | tree utilities library
[Database.SQLite](doc/vital/Database/SQLite.txt) | sqlite utilities library
[DateTime](doc/vital/DateTime.txt)		 | date and time library
[Experimental.Functor](doc/vital/Experimental/Functor.txt) | Utilities for functor
[Hash.MD5](doc/vital/Hash/MD5.txt) | MD5 encoding
[Interpreter.Brainf__k](doc/vital/Interpreter/Brainf__k.txt) | Brainf\*\*k interpreter
[Locale.Message](doc/vital/Locale/Message.txt)	 | very simple message localization library
[Lua.Prelude](doc/vital/Lua/Prelude.txt)	 | crucial functions for lua integration
[Mapping](doc/vital/Mapping.txt)		 | Utilities for mapping
[Math](doc/vital/Math.txt)			 | Mathematical functions
[OptionParser](doc/vital/OptionParser.txt)	 | Option parser library for Vim
[Prelude](doc/vital/Prelude.txt)		 | crucial functions
[Process](doc/vital/Process.txt)		 | Utilities for process
[Random.Mt19937ar](doc/vital/Random/Mt19937ar.txt)| random number generator using mt19937ar
[Random.Xor128](doc/vital/Random/Xor128.txt)	 | random number generator using xor128
[Random](doc/vital/Random.txt)			 | Random utility frontend library
[Stream](doc/vital/Stream.txt)			 | A streaming library
[System.Cache](doc/vital/System/Cache.txt)	 | An unified cache system
[System.File](doc/vital/System/File.txt)	 | filesystem utilities library
[System.Filepath](doc/vital/System/Filepath.txt) | path string utilities library
[System.Process](doc/vital/System/Process.txt)	 | A cross-platform process utilities
[Text.CSV](doc/vital/Text/CSV.txt)		 | CSV library
[Text.INI](doc/vital/Text/INI.txt)		 | INI file library
[Text.LTSV](doc/vital/Text/LTSV.txt)		 | LTSV library
[Text.Lexer](doc/vital/Text/Lexer.txt)		 | lexer library
[Text.Parser](doc/vital/Text/Parser.txt)	 | parser library
[Text.Sexp](doc/vital/Text/Sexp.txt)	         | S-Expression parser
[Text.TOML](doc/vital/Text/TOML.txt)		 | TOML library
[Text.Table](doc/vital/Text/Table.txt)		 | Character table library
[Vim.BufferManager](doc/vital/Vim/BufferManager.txt)  | buffer manager
[Vim.Buffer](doc/vital/Vim/Buffer.txt)		 | Vim's buffer related stuff in general
[Vim.Compat](doc/vital/Vim/Compat.txt)		 | Vim compatibility wrapper functions
[Vim.Guard](doc/vital/Vim/Guard.txt)		 | Guard options/variables
[Vim.Message](doc/vital/Vim/Message.txt)	 | Vim message functions
[Vim.Python](doc/vital/Vim/Python.txt)		 | +python/+python3 compatibility functions
[Vim.ScriptLocal](doc/vital/Vim/ScriptLocal.txt) | Get script-local things
[Vim.Search](doc/vital/Vim/Search.txt)		 | Vim's \[I like function
[Vim.ViewTracer](doc/vital/Vim/ViewTracer.txt) | Trace window and tabpage
[Web.HTML](doc/vital/Web/HTML.txt)		 | HTML parser written in pure Vim script
[Web.HTTP](doc/vital/Web/HTTP.txt)		 | simple HTTP client library
[Web.JSON](doc/vital/Web/JSON.txt)		 | JSON parser written in pure Vim script
[Web.URI](doc/vital/Web/URI.txt)		 | URI manipulation library
[Web.XML](doc/vital/Web/XML.txt)		 | XML parser written in pure Vim script

... and you can also create your own vital modules. Please see [External vital modules](https://github.com/vim-jp/vital.vim/wiki/External-vital-modules) for more information.

## Let's get started

### Install modules for your own plugin

Use `:Vitalize` to install modules.
Please see [the help](doc/vitalizer.txt) for more details.

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
let s:V = vital#ujihisa#new()
function! ujihisa#util#system(...)
  return call(s:V.system, a:000, s:V)
endfunction
```

and then you can call functions by `ujihisa#util#system()`, without taking care
of `vital.vim` itself. It's all hidden.

Vital has module system. The below is an example to import/load a module
`Data.OrderedSet` and to call a function `f()` of the module.

```vim
" Recommended way
let s:V = vital#ujihisa#new()
let s:O = s:V.import('Data.OrderedSet')
call s:O.f()
```

or

```vim
" Recommended way only if you rarely use the module
let s:V = vital#ujihisa#new()
call s:V.load('Data.OrderedSet')
call s:V.Data.OrderedSet.f()
```

or

```vim
" Available, but we don't recommend this very much
let s:V = vital#ujihisa#new()
call s:V.import('Data.OrderedSet', s:)
call s:f()
```

We recommend you to use a capital letter for a Vital module dictionary to assign.

## Plugins Using vital.vim
A lot of vim plugins are using vital.vim
  - [wiki](https://github.com/vim-jp/vital.vim/wiki#plugins-that-use-vitalvim)
  - [google search](https://www.google.co.jp/search?q=filetype%3Avital%20site%3Ahttps%3A%2F%2Fgithub.com)

### Badges

It is not necessary but we recommend to add a badge to your project README to make the vital.vim developers happy ;-)
The following is a markdown snippet.

```
[![Powered by vital.vim](https://img.shields.io/badge/powered%20by-vital.vim-80273f.svg)](https://github.com/vim-jp/vital.vim)
```

The badge uses [Shields.io](http://shields.io/) so you can customize the looks as like:

- [![Powered by vital.vim](https://img.shields.io/badge/powered%20by-vital.vim-80273f.svg)](https://github.com/vim-jp/vital.vim) (Default)
- [![Powered by vital.vim](https://img.shields.io/badge/powered%20by-vital.vim-80273f.svg?style=plastic)](https://github.com/vim-jp/vital.vim) by adding `?style=plastic`
- [![Powered by vital.vim](https://img.shields.io/badge/powered%20by-vital.vim-80273f.svg?style=flat)](https://github.com/vim-jp/vital.vim) by adding `?style=flat`
- [![Powered by vital.vim](https://img.shields.io/badge/powered%20by-vital.vim-80273f.svg?style=flat-square)](https://github.com/vim-jp/vital.vim) by adding `?style=flat-square`

## If you want to become a vital developer

[Become a vital.vim Developer](https://github.com/vim-jp/vital.vim/wiki/Become-a-vital.vim-Developer)

## References

* [Delegation in Vim script](http://ujihisa.blogspot.com/2011/02/delegation-in-vim-script.html)
* [Core concept of vital (in Japanese)](http://d.hatena.ne.jp/thinca/20110310/1299768323)
* [How to make a vital module (in Japanese)](http://d.hatena.ne.jp/thinca/20110311/1299769233)
* [API Reference (in Japanese)](http://d.hatena.ne.jp/kanno_kanno/20120107/1325949855)
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
* ![](https://avatars1.githubusercontent.com/u/546312?v=3&s=80)
  [lambdalisue](https://github.com/lambdalisue)
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
