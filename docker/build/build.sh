#!/usr/bin/env bash
# shellcheck disable=SC1090
source "${SHELL_HOME}"common/common.sh

function build_docker_then_push() {
  local tag=$1 image platforms
  image="mzdjy/build:$tag-auto"
  platforms=${DOCKER_BUILD_PLATFORMS:-linux/amd64,linux/arm64}
  sendLog "do build and push $image." 0
  pushd "$tag" || exit 1
  if [ "${tag}" = "hosts-tools" ] && docker buildx version &>/dev/null; then
    sendLog "do multi-arch build and push $image for ${platforms}." 0
    docker buildx build --platform "${platforms}" -t "${image}" . --push
  else
    docker build . -t "${image}" -q
    docker push "${image}"
  fi
  popd || exit 1
}
cd "${SHELL_HOME}docker/build/docker" || exit 1
# shellcheck disable=SC2010
multiProcess build_docker_then_push "$(ls |grep -v openclaw | grep -v '.sh')"
