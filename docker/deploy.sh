#!/bin/bash
set -euo pipefail

# To be invoked from circleci

if [ $# -lt 1 ]; then
    echo "Usage: $0 DOCKER_TAG. Optionally, you can set the environment variable SKIP_ASSETS_COMPILATION."
    exit 1
fi

git describe --always > VERSION

TAG=${1/\//_}

docker login -e ${DOCKER_EMAIL} -u ${DOCKER_USER} -p ${DOCKER_PASS} ${DOCKER_REGISTRY}
docker build --build-arg SKIP_ASSETS_COMPILATION=1 -t vitalwave .
docker tag vitalwave ${DOCKER_REPOSITORY}:$TAG
docker push ${DOCKER_REPOSITORY}:$TAG
