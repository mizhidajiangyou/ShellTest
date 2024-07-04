#!/usr/bin/env bash

#e.g. ./docker/pack_deployment.sh build project_name v0.0.1 x86
# set -xe
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
  rm -rf docker/deployment/install docker/deployment/docker docker/deployment/images
}

function init_install_file() {
    if  ! checkDir docker/project/"$project";then
      sendLog "No such directory !"
      exit 1
    else
      rm -rf docker/deployment/docker docker/deployment/install
      cp -rf docker/project/"$project"/docker  docker/project/"$project"/install docker/deployment
    fi
}

function do_download() {
  sendLog "do download images." 0
  pushd docker/deployment &>/dev/null || exit 1
  if ! bash scripts/save_images.sh;then
    popd &>/dev/null || exit 1
    restore_common_file
    exit 1
  fi
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
  haveVal "$mode"
  haveVal "$project"
  haveVal "$tag"
  if ! checkDir "docker/project/$project";then
    exit 1
  fi
  sendLog "Do make ${tag} package." 1
  init_common_file
  init_install_file
  case ${mode} in
  build|b)
    do_download
    tar_pack
    ;;
  simple|s)
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
project="$2"
tag="$3"
framework=${4:-x86}

main
