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
  local Fin="Fin"
  if (( VERBOSE == 0 )); then
    Fin+="Update"
  fi
  local args=()
  if [[ -n ${VIMPROC} ]]; then
    args+=(--cmd "let g:vimproc_path='${VIMPROC}'")
  fi
  args+=(--cmd "filetype indent on")
  args+=(-S "${1}")
  args+=(-c "${Fin} ${2}")
  ${VIM} "${args[@]}"
}

usage() {
  if (( ${#} != 0 )); then
    echo "${@}" 1>&2
  fi
  cat <<-EOF 1>&2
Usage ${0} [-h][-q][-v][-p <dir>] [spec_file]
    -p: vimproc directory
    -h: display usage text
    -q: quiet mode
    -v: verbose mode
EOF
  exit 1
}

QUIET=0
VERBOSE=0
VIMPROC=
while getopts hqxvp: OPT; do
  case ${OPT} in
  \?) usage "invalid option" ;;
  h)  usage ;;
  x)  check_spec ;;
  q)  (( QUIET++ )) ;;
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
  files=()
  for spec in $(find spec -type f -name "*.vim" -a ! -name "base.vim"); do
    echo "Testing... ${spec}"
    # spec/*.vim -> ${T}/*.out
    f=${spec/spec\/}
    f="${T}"/${spec%%.vim}.out
    dir="$(dirname "${f}")"
    if [[ ! -d ${dir} ]]; then
      mkdir -p "${dir}"
    fi
    files+=("${f}")
    do_test "${spec}" "${f}"
  done
  for f in "${files[@]}"; do
    if [[ ! -f ${f} ]]; then
      echo "Error: Vim aborted!"
      exit 1
    fi
    cat "${f}" >>"${SPEC_RESULT}"
    rm -f "${f}"
  done
  echo Done.
fi

echo
if (( QUIET == 0 )); then
  cat "${SPEC_RESULT}"
elif grep -v "^\(\[.\]\|$\)" "${SPEC_RESULT}"; then
  echo
fi

TESTS=$(grep "^\[.\]" "${SPEC_RESULT}" | wc -l)
FAILED_TESTS=$(grep "^\[F\]" "${SPEC_RESULT}" | wc -l)
if (( FAILED_TESTS == 0 )); then
  echo "${TESTS} tests success"
  exit 0
else
  FAILED_ASSERTS=$(grep " - " "${SPEC_RESULT}" | wc -l)
  echo "FAILURE!"
  echo "${TESTS} tests. Failure: ${FAILED_TESTS} tests, ${FAILED_ASSERTS} assertions"
  exit 1
fi
