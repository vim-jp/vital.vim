#!/bin/bash

set -ev

if [[ "$VIM_VERSION" = "nvim" ]]; then
	case "${TRAVIS_OS_NAME}" in
		linux)
			tmp=$(mktemp -d)
			url=https://github.com/neovim/neovim
			git clone -q --depth 1 --single-branch $url $tmp
			cd $tmp
			make deps
			make -j2 CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX:PATH=$HOME/neovim" CMAKE_BUILD_TYPE=Release
			make install
			;;
		osx)
			brew update
			brew upgrade
			brew install neovim/neovim/neovim
			;;
		*)
			echo "Unknown value of \${TRAVIS_OS_NAME}: ${TRAVIS_OS_NAME}"
			exit 65
			;;
	esac
else
	case "${TRAVIS_OS_NAME}" in
		linux)
			git clone --depth 1 --branch "${VIM_VERSION}" https://github.com/vim/vim /tmp/vim
			cd /tmp/vim
			./configure --prefix="${HOME}/vim" --with-features=huge \
				--enable-pythoninterp --enable-python3interp \
        --enable-rubyinterp \
				--enable-luainterp --enable-fail-if-missing
			make -j2
			make install
			;;
		osx)
			brew update
			brew upgrade
			brew install lua python ruby
			brew install vim --with-lua
			;;
		*)
			echo "Unknown value of \${TRAVIS_OS_NAME}: ${TRAVIS_OS_NAME}"
			exit 65
			;;
	esac
fi