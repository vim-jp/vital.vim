#!/bin/bash

set -ev

REVIEWDOG_VERSION=0.9.9
VINT_VERSION=0.3.18

mkdir -p ~/bin/ && export export PATH="~/bin/:$PATH"

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
