#!/bin/bash

if [[ "$TRAVIS" != "true" ]]; then
  echo "This script is intended to be run on Travis CI" 1>&2
  exit 1
fi

set -ev

REVIEWDOG_VERSION=0.9.12
VINT_VERSION=0.3.21

mkdir -p ~/bin/ && export PATH="~/bin/:$PATH"

# Install https://github.com/reviewdog/reviewdog/releases
curl -sfL \
  https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh |\
  sh -s -- -b ~/bin "v${REVIEWDOG_VERSION}"

pip3 install --user vim-vint=="${VINT_VERSION}"

# Install vim-vimlint
git clone --depth 1 https://github.com/syngan/vim-vimlint /tmp/vim-vimlint
git clone --depth 1 https://github.com/ynkdir/vim-vimlparser /tmp/vim-vimlparser
export VIMLINT_PATH="/tmp/vim-vimlint"
export VIMLPARSER_PATH="/tmp/vim-vimlparser"
cp ./scripts/vimlint ~/bin/

curl -L -o ./install-misspell.sh https://git.io/misspell \
  && sh ./install-misspell.sh -b ~/bin

# Install dependencies of scripts/lint-throw.go
go get -d -v ./scripts

# Run reviewdog.
reviewdog -reporter=github-pr-check

# Check tag name conflicts
vim --cmd "try | helptags doc/ | catch | cquit | endtry" --cmd quit

# Validate changelog
ruby scripts/check-changelog.rb
