#!/usr/bin/env bash
# shellcheck disable=SC1090
source "${SHELL_HOME}"common/common.sh

function build_docker_then_push() {
  local tag=$1 image
  image="mzdjy/build:$tag-auto"
  sendLog "do build and push $image." 0
  pushd "$tag"  || exit 1
  docker build . -t "${image}"
  docker push "${image}"
  popd || exit 1
}
cd "$SHELL_HOME/docker/build/docker" || exit 1
# shellcheck disable=SC2010
multiProcess build_docker_then_push "$(ls |grep -v '.sh')"
