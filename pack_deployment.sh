#!/usr/bin/env bash

# e.g.
# build docker package  ./pack_deployment.sh build project_name v0.0.1 x86 docker
# build k8s package ./pack_deployment.sh simple project_name v0.0.1 x86 k8s
# build system package ./pack_deployment.sh simple project_name v0.0.1 x86 direct

# shellcheck disable=SC1090
source "${SHELL_HOME}"common/common.sh

function init_common_file() {
  bash build.sh "${build_type}"/deployment/scripts/common.sh .common_file_resulet.sh
  cp "${build_type}"/deployment/scripts/common.sh .common_file_bak.sh
  cp .common_file_resulet.sh "${build_type}"/deployment/scripts/common.sh
}

function restore_common_file() {
  cp .common_file_bak.sh "${build_type}"/deployment/scripts/common.sh
  rm -rf .common_file_bak.sh .common_file_resulet.sh*
  rm -rf "${build_type}"/deployment/install "${build_type}"/deployment/"${build_type}" "${build_type}"/deployment/images
}

function init_install_file() {
  if ! checkDir "${build_type}"/project/"$project"; then
    sendLog "No such directory !" 3
    exit 1
  else
    rm -rf "${build_type}"/deployment/"${build_type}" "${build_type}"/deployment/install
    if [ "${framework}" = "arm64" ]; then
      cp -rf "${build_type}"/project/"$project"/images.cfg-arm64 "${build_type}"/project/"$project"/images.cfg
    else
      cp -rf "${build_type}"/project/"$project"/images.cfg-x86 "${build_type}"/project/"$project"/images.cfg
    fi
    cp -rf "${build_type}"/project/"$project"/* "${build_type}"/deployment
  fi
}

function do_download() {
  sendLog "do download images." 0
  pushd "${build_type}"/deployment &>/dev/null || exit 1
  if ! bash scripts/save_images.sh; then
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
  if tar -zcvf pack/mz-"${build_type}"-"$tag"-"$framework".tar.gz "${build_type}"/deployment &>/dev/null; then
    sendLog "Successful! Your package is pack/mz-${build_type}-$tag-$framework.tar.gz" 1 g
  else
    sendLog "Tar pack/mz-${build_type}-$tag-$framework.tar.gz failed!" 3
  fi
  popd &>/dev/null || exit 1
}

function main() {
  haveVal "$mode"
  haveVal "$project"
  haveVal "$tag"
  if ! checkDir "${build_type}/project/$project"; then
    exit 1
  fi
  sendLog "Do make ${tag} package." 1
  init_common_file
  init_install_file
  case ${mode} in
  build | b)
    do_download
    tar_pack
    ;;
  simple | s)
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
build_type=${5:-docker}
artifact=${6:-artifact}

main
