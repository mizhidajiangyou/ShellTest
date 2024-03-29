#!/usr/bin/env bash

source scripts/common.sh

function do_install() {
  local ser
  ser=$1
  ./install/install_"${ser}".sh
  pushd docker/"${ser}" &>/dev/null || exit 1
  sendLog "start ${ser} ..."
  if ! ./start.sh; then
    sendLog "start ${ser} failed! " 3
    exit 1
  fi
  popd &>/dev/null || exit 1

}

function main() {
  for_service_do do_install
}

main
