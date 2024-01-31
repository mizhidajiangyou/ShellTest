#!/usr/bin/env bash

#e.g. ./docker/pack_deployment.sh build v0.0.1 x86

# shellcheck disable=SC1090
source "${SHELL_HOME}"common/common.sh

function init_common_file() {
  bash build.sh docker/deployment/scripts/common.sh .common_file_resulet.sh
  cp docker/deployment/scripts/common.sh .common_file_bak.sh
  cp .common_file_resulet.sh docker/deployment/scripts/common.sh
}

function restore_common_file() {
  cp .common_file_bak.sh docker/deployment/scripts/common.sh
  rm -rf .common_file_bak.sh .common_file_resulet.sh*
}

function do_download() {
  sendLog "do download images." 0
  pushd docker/deployment &>/dev/null || exit 1
  bash scripts/save_images.sh
  popd &>/dev/null || exit 1
}

function tar_pack() {
  pushd "$SHELL_HOME" &>/dev/null || exit 1
  if [ ! -d "pack" ]; then
    mkdir -p pack/
  fi
  if tar -zcvf pack/mz-docker-"$tag"-"$framework".tar.gz docker/deployment &> /dev/null;then
    sendLog "Successful! Your package is pack/mz-docker-$tag-$framework.tar.gz" 1 g
  else
    sendLog "Tar pack/mz-docker-$tag-$framework.tar.gz failed!" 3
  fi
  popd &>/dev/null || exit 1
}

function main() {
  sendLog "Do make ${tag} package." 1
  init_common_file
  case ${mode} in
  build)
    do_download
    tar_pack
    ;;
  simple)
    tar_pack
    ;;
  *)
    sendLog "No ${mode} mode ,do noting !"
    ;;
  esac
  restore_common_file

}

# tag
mode="$1"
tag="$2"
framework=${3:-x86}

main
