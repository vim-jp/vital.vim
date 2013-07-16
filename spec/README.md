mostly for CI so far.

on vimshell

    $ texe vim -u NONE -i NONE -N --cmd 'filetype indent on' -S spec/prelude.vim -c 'Fin /tmp/prelude.result'

for gui vim (example: MacVim):

    $ cd {repository_root}
    $ /Applications/MacVim.app/Contents/MacOS/Vim -g -u NONE -i NONE -N --cmd 'filetype indent on' -S spec/prelude.vim -c 'Fin /tmp/prelude.result'

unix

    $ cd {repository_root}
    # run all test
    $ ./spec.sh
    # run specify test
    $ ./spec.sh spec/data/string.vim

windows

    > cd {repository_root}
    # run all test
    > spec.bat
    # run specify test
    > spec.bat spec¥data¥string.vim

otherwise

    :VimProcBang vim -u NONE -i NONE -N --cmd 'filetype indent on' -S spec/prelude.vim -c 'Fin /tmp/prelude.result'

Then read /tmp/prelude.result and make sure everything is dot
