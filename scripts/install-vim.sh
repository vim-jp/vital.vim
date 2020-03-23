#!/bin/bash

set -ev

: ${TMPDIR:=/tmp}

case "${TRAVIS_OS_NAME}" in
	linux)
		if [[ -z "${VIM_VERSION}" ]]; then
			exit
		fi
		git clone --depth 1 --branch "${VIM_VERSION}" https://github.com/vim/vim "${TMPDIR}/vim"
		cd "${TMPDIR}/vim"
		./configure --prefix="${HOME}/vim" --with-features=huge --with-lua-prefix="${HOME}/lua" \
			--enable-luainterp --enable-pythoninterp --enable-python3interp --enable-fail-if-missing
		make -j2
		make install
		VIM_BIN=vim/bin/vim
		;;
	osx)
		VIM_URL=$(curl -s --retry 3 https://vim-jp.org/redirects/macvim-dev/macvim/latest.json \
			| sed 's@.*"redirect_url":"\([^"]*\)".*@\1@')
		if [[ -z "${VIM_URL}" ]]; then
			echo "Can't get Vim's URL"
			exit 64
		fi
		echo "Download from ${VIM_URL}"
		curl -L -s -o "${TMPDIR}/MacVim.dmg" "${VIM_URL}"
		hdiutil attach -quiet -mountpoint "/Volumes/MacVim" "${TMPDIR}/MacVim.dmg"
		cp -a "/Volumes/MacVim/MacVim.app" "${HOME}"
		hdiutil detach "/Volumes/MacVim"
		VIM_BIN=MacVim.app/Contents/MacOS/Vim
		;;
	*)
		echo "Unknown value of \${TRAVIS_OS_NAME}: ${TRAVIS_OS_NAME}"
		exit 65
		;;
esac

mkdir -p "${HOME}/bin"
cat <<EOT >"${HOME}/bin/vim"
#!/bin/bash
export LD_LIBRARY_PATH=\${HOME}/lua/lib:\${LD_LIBRARY_PATH}
exec "\${HOME}/${VIM_BIN}" "\$@"
EOT
chmod +x "${HOME}/bin/vim"
