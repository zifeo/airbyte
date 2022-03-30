#!/usr/bin/env bash

set -e

. tools/lib/lib.sh

if [[ -z "${DOCKER_PASSWORD}" ]]; then
  echo 'DOCKER_PASSWORD for airbytebot not set.';
  exit 1;
fi

docker login -u airbytebot -p "${DOCKER_PASSWORD}"

PREV_VERSION=$(grep -w VERSION .env | cut -d"=" -f2)

[[ -z "$PART_TO_BUMP" ]] && echo "Usage ./tools/bin/release_version.sh (major|minor|patch)" && exit 1

# uses .bumpversion.cfg to find files to bump
# requires no git diffs to run
# commits the bumped versions code to your branch
pip install bumpversion
# use the main .bumpversion.cfg  but only modify 
bumpversion --no-configured-files "$PART_TO_BUMP" octavia-cli/install.sh octavia-cli/README.md  octavia-cli/Dockerfile

NEW_VERSION=$(grep -w VERSION .env | cut -d"=" -f2)
GIT_REVISION=$(git rev-parse HEAD)
[[ -z "$GIT_REVISION" ]] && echo "Couldn't get the git revision..." && exit 1
echo "Bumped version from ${PREV_VERSION} to ${NEW_VERSION}"

echo "Building and publishing OCTAVIA version $NEW_VERSION for git revision $GIT_REVISION..."
VERSION=$NEW_VERSION SUB_BUILD=OCTAVIA_CLI ./gradlew clean build
./octavia-cli/publish.sh ${NEW_VERSION} ${GIT_REVISION}
echo "Completed building and publishing OCTAVIA..."