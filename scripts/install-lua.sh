#!/bin/bash

set -ev

LUA_DIST=lua-5.3.5

case "${TRAVIS_OS_NAME}" in
	linux)
		LUA_TARGET=linux
		LUA_SHLIB=liblua.so
		;;
	osx)
		LUA_TARGET=macosx
		LUA_SHLIB=liblua5.3.dylib
		;;
	*)
		echo "Unknown value of \${TRAVIS_OS_NAME}: ${TRAVIS_OS_NAME}"
		exit 65
		;;
esac

cd "${TMPDIR:-/tmp}"
curl -LOs "https://www.lua.org/ftp/${LUA_DIST}.tar.gz"
tar xf "${LUA_DIST}.tar.gz"
cd "${LUA_DIST}"
cat <<EOT >src/Makefile.shared
LUA_SO=	${LUA_SHLIB}

\$(LUA_SO): \$(BASE_O)
	\$(CC) -shared -o \$@ \$^
EOT
echo 'include Makefile.shared' >>src/Makefile
make "${LUA_TARGET}" MYCFLAGS='-fPIC -fno-common'
make -C src "${LUA_SHLIB}"
make install INSTALL_TOP="${HOME}/lua" TO_LIB="${LUA_SHLIB}"
cd "${HOME}/lua/lib"
