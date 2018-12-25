#!/bin/bash

set -ev

case "${TRAVIS_OS_NAME}" in
	linux)
		if [[ "${VIM_VERSION}" == "" ]]; then
			exit
		fi
		git clone --depth 1 --branch "${VIM_VERSION}" https://github.com/vim/vim /tmp/vim
		cd /tmp/vim
		./configure --prefix="${HOME}/vim" --with-features=huge --enable-pythoninterp \
			--enable-python3interp --enable-fail-if-missing
		make -j2
		make install
		;;
	osx)
		curl -q http://vim-jp.org/redirects/splhack/macvim-kaoriya/latest/ | grep location= | sed -E 's/^[^"]+"([^"]+)".*/\1/g' | xargs curl -L -o MacVim.dmg
		hdiutil mount MacVim.dmg
		installer_dir='/Volumes/MacVim*'
		(cd $installer_dir && cp -r MacVim.app /Applications/)
		# Instead of --with-override-system-vim, manually link the executable because
		# it prevents MacVim installation with a bottle.
		ln -sf "/Applications/MacVim.app/Contents/MacOS/Vim" "/usr/local/bin/vim"
		hdiutil detach $installer_dir
		;;
	*)
		echo "Unknown value of \${TRAVIS_OS_NAME}: ${TRAVIS_OS_NAME}"
		exit 65
		;;
esac
