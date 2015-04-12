# vital.vim [![Build Status](https://travis-ci.org/vim-jp/vital.vim.svg?branch=master)](https://travis-ci.org/vim-jp/vital.vim)

[![Join the chat at https://gitter.im/vim-jp/vital.vim](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/vim-jp/vital.vim?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

A comprehensive Vim utility functions for Vim plugins.

This is like a plugin which has both aspects of
[Bundler](http://gembundler.com/) and [jQuery](http://jquery.com/) at the same
time.

## Targets

If you are a Vim user who doesn't make Vim plugins, please ignore this page.

If you are a Vim plugin author, please check this out.

## What vital.vim provides

module						 | description
------------------------------------------------ | ------------------------------
[Assertion](doc/vital-assertion.txt)		 | assertion library
[Bitwise](doc/vital-bitwise.txt)		 | bitwise operators
[ConcurrentProcess](doc/vital-concurrent_process.txt)	 | manages processes concurrently with vimproc
[Data.Base64](doc/vital-data-base64.txt)	 | base64 utilities library
[Data.Closure](doc/vital-data-closure.txt)	 | Provide Closure object
[Data.Collection](doc/vital-data-collection.txt) | Utilities both for list and dict
[Data.Dict](doc/vital-data-dict.txt)		 | dictionary utilities library
[Data.LazyList](doc/vital-data-lazylist.txt)	 | lazy list including file io
[Data.List](doc/vital-data-list.txt)		 | list utilities library
[Data.Optional](doc/vital-data-optional.txt)	 | optional value library
[Data.OrderedSet](doc/vital-data-ordered_set.txt)| ordered collection library
[Data.String](doc/vital-data-string.txt)	 | string utilities library
[Data.Tree](doc/vital-data-tree.txt)		 | tree utilities library
[Database.SQLite](doc/vital-database-sqlite.txt) | sqlite utilities library
[DateTime](doc/vital-date_time.txt)		 | date and time library
[Experimental.Functor](doc/vital-experimental-functor.txt) | Utilities for functor
[Interpreter.Brainf__k](doc/vital-interpreter-brainf__k.txt) | Brainf\*\*k interpreter
[Locale.Message](doc/vital-locale-message.txt)	 | very simple message localization library
[Lua.Prelude](doc/vital-lua-prelude.txt)	 | crucial functions for lua integration
[Mapping](doc/vital-mapping.txt)		 | Utilities for mapping
[Math](doc/vital-math.txt)			 | Mathematical functions
[OptionParser](doc/vital-option_parser.txt)	 | Option parser library for Vim
[Prelude](doc/vital-prelude.txt)		 | crucial functions
[Process](doc/vital-process.txt)		 | Utilities for process
[ProcessManager](doc/vital-process_manager.txt)  | process manager with vimproc
[Random.Mt19937ar](doc/vital-random-mt19937ar.txt)| random number generator using mt19937ar
[Random.Xor128](doc/vital-random-xor128.txt)	 | random number generator using xor128
[Random](doc/vital-random.txt)			 | Random utility frontend library
[System.Cache](doc/vital-system-cache.txt)	 | store/restore cache into/from file
[System.File](doc/vital-system-file.txt)	 | filesystem utilities library
[System.Filepath](doc/vital-system-filepath.txt) | path string utilities library
[Text.CSV](doc/vital-text-csv.txt)		 | CSV library
[Text.INI](doc/vital-text-ini.txt)		 | INI file library
[Text.LTSV](doc/vital-text-ltsv.txt)		 | LTSV library
[Text.Lexer](doc/vital-text-lexer.txt)		 | lexer library
[Text.Parser](doc/vital-text-parser.txt)	 | parser library
Text.Sexp  |	
[Text.TOML](doc/vital-text-toml.txt)		 | TOML library
[Text.Table](doc/vital-text-table.txt)		 | Character table library
[Vim.Buffer](doc/vital-vim-buffer.txt)		 | Vim's buffer related stuff in general
[Vim.BufferManager](doc/vital-vim-buffer_manager.txt)  | buffer manager
[Vim.Compat](doc/vital-vim-compat.txt)		 | Vim compatibility wrapper functions
[Vim.Message](doc/vital-vim-message.txt)	 | Vim message functions
[Vim.Search](doc/vital-vim-search.txt)		 | Vim's [I like function
[Vim.ScriptLocal](doc/vital-vim-script_local.txt)		 | Get script-local things
[Web.HTML](doc/vital-web-html.txt)		 | HTML parser written in pure Vim script
[Web.HTTP](doc/vital-web-http.txt)		 | simple HTTP client library
[Web.JSON](doc/vital-web-json.txt)		 | JSON parser written in pure Vim script
Web.URI  |	
[Web.XML](doc/vital-web-xml.txt)		 | XML parser written in pure Vim script

... and more ...


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
* ![](https://avatars2.githubusercontent.com/u/823277?v=3&s=80)
  [rhysd](https://github.com/rhysd)
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
