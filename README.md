# vital.vim [![Build Status](https://travis-ci.org/vim-jp/vital.vim.svg?branch=master)](https://travis-ci.org/vim-jp/vital.vim) [![Build status](https://ci.appveyor.com/api/projects/status/078w3wc2eocwa558/branch/master?svg=true)](https://ci.appveyor.com/project/vim-jp/vital-vim/branch/master) [![codecov](https://codecov.io/gh/vim-jp/vital.vim/branch/master/graph/badge.svg)](https://codecov.io/gh/vim-jp/vital.vim)

[![Join the chat at https://gitter.im/vim-jp/vital.vim](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/vim-jp/vital.vim?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

A comprehensive Vim utility functions for Vim plugins.

## Requirements

Modules in vital.vim basically support Vim 8.1 or later.
We guarantee that the following versions of Vim are supported:
* The latest major version (8.2.\*)
* The previous major version (8.1.\*)

And some modules have stricter requirements and additional dependencies.
Please read the docs of each module before using them.

## Handling libraries in Vim WAS hard

Since Vim script has no built-in module system, using external libraries had been troublesome.

* If you decide to include the libraries in your plugin repository by copy&paste manually:
  You are responsible for updating the libraries by yourself. *sigh*
  You have to find backward-incompatible changes that can break your plugin from every changes between the previous version you installed in the past. *super tedious*
* If you want the plugin users to install the dependent libraries:
  The users will receive additional steps to get it working with your plugin. *not easy*
  Even worse, they may fail to install the dependencies properly. *a bad dream*

## What vital.vim does for the problems

**vital.vim** will embed libraries into your plugin repository and thus your plugin users don't need to install them separately.
Additionally, **vital.vim** can also resolve the dependencies according to the declaration on **vital modules**.

Concretely, **vital.vim** resolves the dependencies among **vital modules** by the module bundler called **vitalizer**.
**vitalizer** can bundle only necessary modules and can update an existing bundle.
On updating the modules, **vitalizer** shows any breaking changes to help you migrate to the new version of **vital modules**.

## What vital.vim provides

Module						 | Description
------------------------------------------------ | ------------------------------
[Assertion](doc/vital/Assertion.txt)		 | assertion library
[Async.Promise](doc/vital/Async/Promise.txt)	 | An asynchronous operation like ES6 Promise
[Bitwise](doc/vital/Bitwise.txt)		 | bitwise operators
[Color](doc/vital/Color.txt)                     | color conversion library between RGB/HSL/terminal code
[ConcurrentProcess](doc/vital/ConcurrentProcess.txt)	 | manages processes concurrently with vimproc
[Data.Base64](doc/vital/Data/Base64.txt)	 | base64 utilities library
[Data.Base64.RFC4648](doc/vital/Data/Base64/RFC4648.txt)	 | base64 RFC4648 utilities library
[Data.Base64.URLSafe](doc/vital/Data/Base64/URLSafe.txt)	 | base64 URLSafe utilities library
[Data.Base32](doc/vital/Data/Base32.txt)	 | base32 utilities library
[Data.Base32.Crockford](doc/vital/Data/Base32/Crockford.txt)	 | base32 Crockford utilities library
[Data.Base32.Hex](doc/vital/Data/Base32/Hex.txt)	 | base32 Hex utilities library
[Data.Base32.RFC4648](doc/vital/Data/Base32/RFC4648.txt)	 | base32 RFC4648 utilities library
[Data.Base16](doc/vital/Data/Base16.txt)	 | base16 utilities library
[Data.BigNum](doc/vital/Data/BigNum.txt)	 | multi precision integer library
[Data.Closure](doc/vital/Data/Closure.txt)	 | Provide Closure object
[Data.Counter](doc/vital/Data/Counter.txt) | Counter library to support convenient tallies
[Data.Dict](doc/vital/Data/Dict.txt)		 | dictionary utilities library
[Data.Either](doc/vital/Data/Either.txt)	 | either value library
[Data.LazyList](doc/vital/Data/LazyList.txt)	 | lazy list including file io
[Data.List](doc/vital/Data/List.txt)		 | list utilities library
[Data.List.Closure](doc/vital/Data/List/Closure.txt)	 | Data.List provider for Data.Closure
[Data.List.Byte](doc/vital/Data/List/Byte.txt)	 | Data.List provider for Bytes-List and other bytes-list like data converter.
[Data.Optional](doc/vital/Data/Optional.txt)	 | optional value library
[Data.OrderedSet](doc/vital/Data/OrderedSet.txt)| ordered collection library
[Data.Set](doc/vital/Data/Set.txt)		 | set and frozenset data structure ported from python
[Data.String](doc/vital/Data/String.txt)	 | string utilities library
[Data.String.Interpolation](doc/vital/Data/String/Interpolation.txt)		 | build string with ${}
[Data.Tree](doc/vital/Data/Tree.txt)		 | tree utilities library
[Database.SQLite](doc/vital/Database/SQLite.txt) | sqlite utilities library
[DateTime](doc/vital/DateTime.txt)		 | date and time library
[Experimental.Functor](doc/vital/Experimental/Functor.txt) | Utilities for functor
[Hash.HMAC](doc/vital/Hash/HMAC.txt) | Hash-based Message Authentication Code
[Hash.MD5](doc/vital/Hash/MD5.txt) | MD5 encoding
[Hash.SHA1](doc/vital/Hash/SHA1.txt) | SHA1 encoding
[Interpreter.Brainf__k](doc/vital/Interpreter/Brainf__k.txt) | Brainf\*\*k interpreter
[Locale.Message](doc/vital/Locale/Message.txt)	 | very simple message localization library
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
[Vim.WindowLayout](doc/vital/Vim/WindowLayout.txt)		 | lays out windows declaratively
[Web.HTML](doc/vital/Web/HTML.txt)		 | HTML parser written in pure Vim script
[Web.HTTP](doc/vital/Web/HTTP.txt)		 | simple HTTP client library
[Web.JSON](doc/vital/Web/JSON.txt)		 | JSON parser written in pure Vim script
[Web.URI](doc/vital/Web/URI.txt)		 | URI manipulation library
[Web.XML](doc/vital/Web/XML.txt)		 | XML parser written in pure Vim script

... and you can also create your own vital modules. Please see [External vital modules](https://github.com/vim-jp/vital.vim/wiki/External-vital-modules) for more information.

## Let's get started

### Install modules for your own plugin

Use `:Vitalize` to install modules.
Assuming your Vim plugin name is `your_plugin_name` and plugin directory is `your_plugin_dir`. 
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

Assuming your Vim plugin name is `your_plugin_name`. You can define your utility
function set `your_plugin_name#util` just by

```vim
let s:Process = vital#your_plugin_name#import('System.Process')

function! your_plugin_name#util#system(...)
  return s:Process.execute(a:000)
endfunction
" run
" echo your_plugin_name#util#system('echo','abc')
" -> $ echo abc
```

and then you can call functions by `your_plugin_name#util#system()`, without taking care
of `vital.vim` itself. It's all hidden.

Vital has module system. The below is an example to import/load a module
`Math` and to call a function `lcm()` of the module.

```vim
" Recommended way
let s:M = vital#your_plugin_name#import('Math')
call s:M.lcm([2, 3, 4])
" -> 12
```

or

```vim
" Alternative way
let s:V = vital#your_plugin_name#new()
let s:M = s:V.import('Math')
call s:M.lcm([2, 3, 4])
" -> 12
```

or

```vim
" Alternative way only if you rarely use the module
let s:V = vital#your_plugin_name#new()
call s:V.load('Math')
call s:V.Math.lcm([2, 3, 4])
" -> 12
```

or

```vim
" Available, but we don't recommend this very much
let s:V = vital#your_plugin_name#new()
call s:V.import('Math', s:)
call s:lcm([2, 3, 4])
" -> 12
```

We recommend you to use a capital letter for a Vital module dictionary to assign.

## Plugins Using vital.vim
A lot of vim plugins are using vital.vim
  - [wiki](https://github.com/vim-jp/vital.vim/wiki#plugins-that-use-vitalvim)
  - [google search](https://www.google.co.jp/search?q=filetype%3Avital%20site%3Ahttps%3A%2F%2Fgithub.com)

### Badges

It is not necessary but we recommend adding a badge to your project README to make the vital.vim developers happy ;-)
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
