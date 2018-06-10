#!/bin/bash

if [[ "$TRAVIS" != "true" ]]; then
  echo "This script is intended to be run on Travis CI" 1>&2
  exit 1
fi

set -ev

REVIEWDOG_VERSION=0.9.9
VINT_VERSION=0.3.18

mkdir -p ~/bin/ && export PATH="~/bin/:$PATH"

# Install https://github.com/haya14busa/reviewdog
curl -fSL \
  https://github.com/haya14busa/reviewdog/releases/download/$REVIEWDOG_VERSION/reviewdog_linux_amd64 \
  -o ~/bin/reviewdog && chmod +x ~/bin/reviewdog

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
