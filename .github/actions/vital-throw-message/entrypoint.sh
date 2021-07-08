#!/bin/sh

cd "$GITHUB_WORKSPACE"

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

go get -d -v ./scripts

go run ./scripts/lint-throw.go $(find autoload/vital/__vital__/ | grep -e '\.vim$') \
   | reviewdog -efm="%f:%l:%c: %m" -name="vital-throw-message"                      \
               -reporter="${INPUT_REPORTER:-'github-pr-check'}"                     \
               -level="${INPUT_LEVEL}"

