#!/bin/bash
set -x

if [[ "$VIM_VERSION" == "nvim" ]]; then
  export PATH="$HOME/neovim/bin:/tmp/vim-themis/bin:$PATH"
  export THEMIS_HOME="/tmp/vim-themis"
  export THEMIS_VIM="nvim"
  export THEMIS_ARGS="-e -s --headless"
  uname -a
  which -a nvim
  which -a themis
  themis --target System.Job --reporter dot
else
  export PATH="$HOME/vim/bin:/tmp/vim-themis/bin:$PATH"
  export THEMIS_HOME="/tmp/vim-themis"
  export THEMIS_VIM="vim"

  uname -a
  which -a vim
  which -a themis
  vim --cmd version --cmd quit
  vim --cmd "try | helptags doc/ | catch | cquit | endtry" --cmd quit
  themis --runtimepath /tmp/vimproc --exclude ConcurrentProcess --reporter dot
fi
