#!/bin/bash
#set -x

T="$(mktemp -d --tmpdir vital_spec.XXXXXXXXXX)" || exit 1
trap "rm -rf '${T}'" EXIT

trap "exit 1" HUP INT QUIT TERM

VIM="vim -u NONE -i NONE -N -e -s"
SPEC_RESULT="${T}"/vital_spec.result

check_spec() {
  local file
  cd autoload/vital/__latest__
  for file in $(find . -name "*.vim" | \
                sed 's/\([a-z]\)\([A-Z]\)/\1_\2/g' | \
                tr "[A-Z]" "[a-z]"); do
    file=${file#.*/}
    if [[ ! -f ../../../spec/${file} ]]; then
      echo "spec/${file}"
    fi
  done
  cd - >/dev/null
  exit 0
}

do_test() {
  local args=()
  if [[ -n ${VIMPROC} ]]; then
    args+=(--cmd "let g:vimproc_path='${VIMPROC}'")
  fi
  args+=(--cmd "filetype indent on")
  args+=(-S "${1}")
  args+=(-c "FinUpdate ${2}")
  ${VIM} "${args[@]}"
  # report error when Vim was aborted
  local rv="${?}"
  if [[ ! -f ${2} ]]; then
    local M="$(grep "\.import(.*)" "${1}" | head -n 1 | sed "s/.*\.import(.\([^)]\+\).).*/\1/")"
    cat <<-EOF >"${2}"
[E] ${M}

Error
  ${M}
    ! Vim exited with status ${rv}

EOF
  fi
}

usage() {
  if (( ${#} != 0 )); then
    echo "${@}" 1>&2
  fi
  cat <<-EOF 1>&2
Usage ${0} [-h][-v][-p <dir>] [spec_file]
    -p: vimproc directory
    -h: display usage text
    -v: verbose mode
EOF
  exit 1
}

VERBOSE=0
VIMPROC=
while getopts hqxvp: OPT; do
  case ${OPT} in
  \?) usage "invalid option" ;;
  h)  usage ;;
  x)  check_spec ;;
  v)  (( VERBOSE++ )) ;;
  p)
    VIMPROC="${OPTARG}"
    if [[ ! -f ${VIMPROC}/autoload/vimproc.vim ]]; then
      usage "invalid argument -p"
    fi ;;
  esac
done
shift $(( OPTIND - 1 ))

if (( ${#} > 1 )); then
  usage "too many arguments"
fi

if (( ${#} == 1 )); then
  spec="${1}"
  if [[ ! -f ${spec} ]]; then
    echo "Error: file not found: ${spec}" 1>&2
    exit 1
  fi
  do_test "${spec}" "${SPEC_RESULT}"
else
  # all test
  spec_out="${T}"/spec.out
  for spec in $(find spec -type f -name "*.vim" -a ! -name "base.vim"); do
    echo "Testing... ${spec}"
    do_test "${spec}" "${spec_out}"

    cat "${spec_out}" >>"${SPEC_RESULT}"
    rm -f "${spec_out}"
  done
  echo Done.
fi

echo
if (( VERBOSE > 0 )); then
  cat "${SPEC_RESULT}"
elif grep -v "^\(\[.\]\|$\)" "${SPEC_RESULT}"; then
  echo
fi

TESTS=$(grep "^\[.\]" "${SPEC_RESULT}" | wc -l)
F_TESTS=$(grep "^\[F\]" "${SPEC_RESULT}" | wc -l)
E_SPECS=$(grep "^\[E\]" "${SPEC_RESULT}" | wc -l)
if (( F_TESTS == 0 && E_SPECS == 0 )); then
  echo "${TESTS} tests success"
  exit 0
else
  F_ASSERTS=$(grep " - " "${SPEC_RESULT}" | wc -l)
  echo "FAILURE!"
  echo -n "${TESTS} tests. Failure: ${F_TESTS} tests, ${F_ASSERTS} assertions"
  if (( E_SPECS > 0 )); then
    echo ". Error: ${E_SPECS} specs"
  else
    echo
  fi
  exit 1
fi
