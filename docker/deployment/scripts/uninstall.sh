#!/usr/bin/env bash

source scripts/common.sh

function do_uninstall() {
  local ser
  ser=$1
  pushd docker/"${ser}" &>/dev/null || exit 1
  sendLog "stop ${ser} ..."
  if ! ./stop.sh; then
    sendLog "stop ${ser} failed! " 3
    exit 1
  fi
  popd &>/dev/null || exit 1
}

function main() {
  for_service_do do_uninstall
}

main
