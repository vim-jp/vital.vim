#!/bin/bash

set -ev

if [[ "${THEMIS_PROFILE}" == "" ]]; then
    exit
fi

if [[ "${TRAVIS_OS_NAME}" == "osx" ]]; then
    export PATH=$(
    for dir in ${HOME}/Library/Python/*; do
        if [[ -e "${dir}/bin/covimerage" ]]; then
            echo -n "${dir}/bin:"
            break
        fi
    done
    )$PATH
fi

covimerage write_coverage "${THEMIS_PROFILE}"
coverage xml
bash <(curl -s https://codecov.io/bash)
