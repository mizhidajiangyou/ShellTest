#!/usr/bin/env bash

#e.g. ./docker/pack_deployment.sh build v0.0.1 x86

# shellcheck disable=SC1090
source "${SHELL_HOME}"common/common.sh

function do_download() {
  echo "do"
}

function tar_pack() {
  pushd "$SHELL_HOME" &> /dev/null|| exit 1
  if [ ! -d "pack" ]; then
    mkdir -p pack/
  fi
   tar -czvf pack/mz-docker-"$tag"-"$framework".tar.gz docker/deployment
   popd &> /dev/null || exit 1
}

function main() {
  sendLog "Do make ${tag} package." 1
  case ${mode} in
  build)
    do_download
    tar_pack
    ;;
  *)
    sendLog "No ${mode} mode ,do noting !"
    ;;
  esac
}

# tag
mode="$1"
tag="$2"
framework=${3:-x86}

main
