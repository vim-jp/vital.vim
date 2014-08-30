#!/bin/bash
#set -x

VIM="vim -u NONE -i NONE -N"
OUTFILE=/tmp/vital_spec.result

fatal=false

check_spec()
{
  (cd autoload/vital/__latest__;
  for file in `find . -name "*.vim" | \
    sed 's/\([a-z]\)\([A-Z]\)/\1_\2/g' | tr "[:upper:]" "[:lower:]"`
  do
    if [ ! -f ../../../spec/$file ]; then
      echo "$file" | sed 's/^../spec\//'
    fi
  done)
}

do_test()
{
  if [ $VERBOSE -eq 0 ]; then
    FIN="FinUpdate"
  else
    FIN="Fin"
  fi
  if [ "x$VIMPROC" != "x" ]; then
    $VIM \
      --cmd "let g:vimproc_path='${VIMPROC}'" \
      --cmd 'filetype indent on' \
    -S "$1" -c "${FIN} $2" > /dev/null 2>&1
  else
    $VIM  \
      --cmd 'filetype indent on' \
    -S "$1" -c "${FIN} $2" > /dev/null 2>&1
  fi

}

usage()
{
  if [ $# -ne 0 ]; then
    echo "$@" 1>&2
  fi
  cat <<- EOF 1>&2
Usage $0 [-h][-q][-v][-p dir] [spec_file]
    -p: vimproc directory
    -h: display usage text
    -q: quiet mode
    -v: verbose mode
EOF
}

OPT=
QUIET=0
VERBOSE=0
VIMPROC=""
while getopts hqxvp: OPT
do
  case $OPT in
  p)
    VIMPROC=$OPTARG ;;
  x)
    check_spec
    exit 0;;
  q)
    QUIET=1 ;;
  v)
    VERBOSE=1 ;;
  h)
    usage
    exit 1;;
  \?)
    usage "invalid option"
    exit 1 ;;
  esac
done
shift `expr $OPTIND - 1`

if [ $# -gt 1 ]; then
  usage "too many argument"
  exit 1
fi

if [ "x${VIMPROC}" != "x" ]; then
  if [ ! -d "${VIMPROC}" -o ! -f "${VIMPROC}/autoload/vimproc.vim" ]; then
    usage "invalid argument -p"
    exit 1
  fi
fi


cat /dev/null > $OUTFILE
if [ $# -eq 1 ]; then
  # not required '&'(background process)
  SPEC_FILE=$1
  if [ ! -r "${SPEC_FILE}" ]; then
    echo "Error: file not found: ${SPEC_FILE}" 1>&2
    exit 1
  fi
  do_test "${SPEC_FILE}" "${OUTFILE}"
else
  # all test
  for FILE in `find spec -type f -name "*.vim"`
  do
    if [ $FILE != "spec/base.vim" ]; then
      echo Testing... $FILE
      # required '&'(background process)
      OFILE="$OUTFILE.`basename ${FILE}`"
      cat /dev/null > "${OFILE}"
      do_test "${FILE}" "${OFILE}" &
      pids="$pids $!"
    fi
  done
  # From man bash(1)
  # If n is not given, all currently active child processes are waited for,
  # and the return status is zero. If n specifies a non-existent process or
  # job, the return status is 127. Otherwise, the return status is the exit
  # status of the last process or job waited for.
  for p in $pids; do
    wait
    [ $# -ne 127 -a $# -ne 0 ] && fatal=true
  done
  echo Done.

  find spec -type f -name "*.vim" | while read FILE
  do
    OFILE="$OUTFILE.`basename ${FILE}`"
    if [ -f "${OFILE}" ]; then
      cat ${OFILE} >> ${OUTFILE}
      rm -f "${OFILE}"
    fi
  done
fi

if [ $QUIET -eq 0 ]; then
  cat $OUTFILE
else
  grep -v "\[.\]" $OUTFILE | grep -v '^$'
  echo ""
fi

ALL_TEST_NUM=`grep "\[.\]" $OUTFILE | wc -l`
FAILED_TEST_NUM=`grep "\[F\]" $OUTFILE | wc -l`

if [ $FAILED_TEST_NUM -eq 0 ]; then
  echo $ALL_TEST_NUM tests success
  echo
  if [ $fatal = true ]; then
    echo "error: ...but Vim exits with non-zero value."
    exit 1
  fi
  exit 0
else
  FAILED_ASSERT_NUM=`grep " - " $OUTFILE | wc -l`
  echo FAILURE!
  echo $ALL_TEST_NUM tests. Failure: $FAILED_TEST_NUM tests, $FAILED_ASSERT_NUM assertions
  echo
  if [ $fatal = true ]; then
    echo "error: Vim exits with non-zero value."
    exit 1
  fi
  exit 1
fi

