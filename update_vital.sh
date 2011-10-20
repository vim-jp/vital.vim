#!/bin/sh

VITAL_HOME=`dirname "$0"`
TARGET=$1
[ "x$TARGET" == "x" ] && TARGET=`pwd`
[ "x$MSYSTEM" != "x" ] && [ "`which ruby | grep ^/`" != "" ] && TARGET=`echo "$TARGET" | sed 's/^\/\([a-zA-Z]\)/\1:/'`
ruby "$VITAL_HOME/vitalize.rb" "$VITAL_HOME" "$TARGET"
