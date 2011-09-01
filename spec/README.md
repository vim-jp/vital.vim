mostly for CI so far.

on vimshell

    $ texe vim -u NONE -i NONE -N --cmd 'filetype indent on' -S spec/prelude.vim -c 'Fin /tmp/prelude.result'

otherwise

    :VimProcBang vim -u NONE -i NONE -N --cmd 'filetype indent on' -S spec/prelude.vim -c 'Fin /tmp/prelude.result'

Then read /tmp/prelude.result and make sure everything is dot
