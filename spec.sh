#!/bin/bash

VIM="vim -u NONE -i NONE -N"
OUTFILE=/tmp/vital_spec.result

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
  exit 0
}

do_test()
{
  $VIM --cmd 'filetype indent on' -S "$1" -c "FinUpdate $2" > /dev/null 2>&1
}

usage()
{
  cat <<- EOF 1>&2
  Usage $0 [-h][-q] [spec_file]
    -h: display usage text
    -q: quiet mode
EOF
}

OPT=
QUIET=0
while getopts hqx OPT
do
  case $OPT in
  x)
    check_spec
    exit 0;;
  q)
    QUIET=1 ;;
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
    fi
  done
  wait
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
  exit 0
else
  FAILED_ASSERT_NUM=`grep " - " $OUTFILE | wc -l`
  echo FAILURE!
  echo $ALL_TEST_NUM tests. Failure: $FAILED_TEST_NUM tests, $FAILED_ASSERT_NUM assertions
  echo
  exit 1
fi

