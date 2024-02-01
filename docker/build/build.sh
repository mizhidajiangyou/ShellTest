#!/usr/bin/env bash
# shellcheck disable=SC1090
source "${SHELL_HOME}"common/common.sh

function build_docker_then_push() {
  local tag=$1 image
  image="mzdjy/visualization:$tag-auto"
  sendLog "do build and push $image." 0
  docker build . -t "${image}"
  docker push "${image}"
}

multiProcess build_docker_then_push "$(ls docker)"
