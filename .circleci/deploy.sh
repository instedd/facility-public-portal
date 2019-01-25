#!/bin/bash
set -eo pipefail

source <(curl -s https://raw.githubusercontent.com/manastech/ci-docker-builder/3fee09cce08175cfd76a246dd95112686939fb9c/build.sh)

dockerSetup
echo $VERSION > VERSION
dockerBuildAndPush
