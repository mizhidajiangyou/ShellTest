#!/usr/bin/env bash

source scripts/common.sh

function init_docker_network() {
  # shellcheck disable=SC2155
  local network_name="$(configParser network network_name images.cfg)"
  if ! docker network ls | grep -q "${network_name}"; then
    sendLog "docker network ${network_name} not exist, create it" 1
    docker network create -d bridge "${network_name}" --subnet "$(configParser network subnet images.cfg)"
  else
    sendLog "docker network ${network_name} exist, skip create" 0
  fi

}

function do_install() {
  local ser
  ser=$1
  ./install/install_"${ser}".sh
  pushd artifact/"${ser}" &>/dev/null || exit 1
  sendLog "start ${ser} ..."
  if ! ./start.sh; then
    sendLog "start ${ser} failed! " 3
    exit 1
  fi
  popd &>/dev/null || exit 1

}

function main() {
  init_docker_network
  for_service_do do_install
}

main
