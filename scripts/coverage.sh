#!/bin/bash

set -ev

if [[ "${THEMIS_PROFILE}" == "" ]]; then
    exit
fi

covimerage write_coverage $THEMIS_PROFILE
coverage xml
bash <(curl -s https://codecov.io/bash)
