#!/bin/bash
set -eo pipefail

docker-compose run --rm app /bin/sh -c "bundle exec ./bin/rails runner 'File.write \"VERSION\", Settings.version'"
PROJECT_VERSION=`cat VERSION`
rm -f VERSION

if [ "$CIRCLE_TAG" = "" ]; then
  REV=`git rev-parse --short HEAD`
  VERSION="$PROJECT_VERSION-dev-$REV (build $CIRCLE_BUILD_NUM)"
  case $CIRCLE_BRANCH in
    master)
      DOCKER_TAG="dev"
      ;;

    release/*)
      DOCKER_TAG="$PROJECT_VERSION-dev"
      ;;

    build/*)
      DOCKER_TAG="$PROJECT_VERSION-${CIRCLE_BRANCH#build\/}"
      VERSION="$PROJECT_VERSION-${CIRCLE_BRANCH#build\/}-$REV (build $CIRCLE_BUILD_NUM)"
      ;;

    stable)
      echo "Pulling $PROJECT_VERSION and tagging as latest"
      docker login -u ${DOCKER_USER} -p ${DOCKER_PASS} ${DOCKER_REGISTRY}
      docker pull ${DOCKER_REPOSITORY}:${PROJECT_VERSION}
      docker tag ${DOCKER_REPOSITORY}:${PROJECT_VERSION} ${DOCKER_REPOSITORY}:latest
      docker push ${DOCKER_REPOSITORY}:latest
      exit 0
      ;;

    *)
      exit 0
      ;;
  esac
else
  TAG_VERSION="${CIRCLE_TAG/-*/}"
  if [ "$PROJECT_VERSION" != "$TAG_VERSION" ]; then
    echo "Project version and tag differs: $PROJECT_VERSION != $CIRCLE_TAG"
    exit 1
  fi

  VERSION="$CIRCLE_TAG (build $CIRCLE_BUILD_NUM)"
  DOCKER_TAG="$CIRCLE_TAG"

  if [ "$TAG_VERSION" = "$CIRCLE_TAG" ]; then
    EXTRA_DOCKER_TAG="${CIRCLE_TAG%.*}"
  fi
fi

echo "Version: $VERSION"
echo $VERSION > VERSION

# Build and push Docker image
echo "Docker tag: $DOCKER_TAG"
docker build -t ${DOCKER_REPOSITORY}:${DOCKER_TAG} .
docker login -u ${DOCKER_USER} -p ${DOCKER_PASS} ${DOCKER_REGISTRY}
docker push ${DOCKER_REPOSITORY}:${DOCKER_TAG}

# Push extra image on exact tags
if [ "$EXTRA_DOCKER_TAG" != "" ]; then
  echo "Pushing also as $EXTRA_DOCKER_TAG"
  docker tag ${DOCKER_REPOSITORY}:${DOCKER_TAG} ${DOCKER_REPOSITORY}:${EXTRA_DOCKER_TAG}
  docker push ${DOCKER_REPOSITORY}:${EXTRA_DOCKER_TAG}
fi
