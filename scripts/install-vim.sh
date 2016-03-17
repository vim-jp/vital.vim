#!/bin/sh
set -e
if [ x"$HEAD" = "xyes" ]; then
  git clone --depth 1 --single-branch --branch v7.4.1576 https://github.com/vim/vim /tmp/vim
  cd /tmp/vim
  ./configure --prefix="$HOME/vim" --with-features=huge \
    --enable-perlinterp --enable-pythoninterp --enable-python3interp \
    --enable-rubyinterp --enable-luainterp --enable-fail-if-missing
  make -j2
  make install
fi
