#!/bin/sh

if [ -n "${GITHUB_WORKSPACE}" ] ; then
  cd "${GITHUB_WORKSPACE}" || exit 1
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

go run -mod=mod /scripts/lint-throw.go $(find autoload/vital/__vital__/ | grep -e '\.vim$') \
   | reviewdog -efm="%f:%l:%c: %m" -name="vital-throw-message"                      \
               -reporter="${INPUT_REPORTER:-'github-pr-check'}"                     \
               -level="${INPUT_LEVEL}"

