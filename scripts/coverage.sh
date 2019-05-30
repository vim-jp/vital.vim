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

# Workaround: avoid covimerage error in Vim 8.1.0365 or later
vim -u NONE -i NONE -N -e -s '+g/Defined:/d' +wq "${THEMIS_PROFILE}"

covimerage write_coverage "${THEMIS_PROFILE}"
coverage xml
bash <(curl -s https://codecov.io/bash)
